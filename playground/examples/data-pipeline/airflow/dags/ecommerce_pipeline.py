"""
Apache Airflow DAG for E-Commerce Data Pipeline
Implements medallion architecture (Bronze/Silver/Gold)
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.decorators import task, task_group
from airflow.operators.empty import EmptyOperator
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from airflow.providers.amazon.aws.sensors.s3 import S3KeySensor
from airflow.providers.dbt.cloud.operators.dbt import DbtCloudRunJobOperator
from airflow.providers.slack.operators.slack_webhook import SlackWebhookOperator
from airflow.utils.task_group import TaskGroup
from airflow.models import Variable
import json

# Default arguments
default_args = {
    'owner': 'data-engineering',
    'depends_on_past': False,
    'email': ['data-team@example.com'],
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
    'execution_timeout': timedelta(hours=2),
}

# DAG Definition
with DAG(
    dag_id='ecommerce_data_pipeline',
    default_args=default_args,
    description='E-Commerce Data Pipeline with Bronze/Silver/Gold layers',
    schedule_interval='0 2 * * *',  # Daily at 2 AM
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['etl', 'ecommerce', 'production'],
    max_active_runs=1,
) as dag:

    # ========================================================================
    # START
    # ========================================================================
    start = EmptyOperator(task_id='start')

    # ========================================================================
    # DATA QUALITY SENSORS
    # ========================================================================
    with TaskGroup(group_id='data_sensors') as data_sensors:
        orders_sensor = S3KeySensor(
            task_id='wait_for_orders',
            bucket_name='raw-data',
            bucket_key='orders/{{ ds }}/*.parquet',
            wildcard_match=True,
            timeout=3600,
            poke_interval=60,
        )

        products_sensor = S3KeySensor(
            task_id='wait_for_products', 
            bucket_name='raw-data',
            bucket_key='products/{{ ds }}/*.parquet',
            wildcard_match=True,
            timeout=3600,
        )

        customers_sensor = S3KeySensor(
            task_id='wait_for_customers',
            bucket_name='raw-data', 
            bucket_key='customers/{{ ds }}/*.parquet',
            wildcard_match=True,
            timeout=3600,
        )

    # ========================================================================
    # BRONZE LAYER - Raw Data Ingestion
    # ========================================================================
    with TaskGroup(group_id='bronze_layer') as bronze_layer:
        ingest_orders = SparkSubmitOperator(
            task_id='ingest_orders_to_bronze',
            application='s3://spark-jobs/bronze/ingest_orders.py',
            conn_id='spark_default',
            conf={
                'spark.executor.memory': '4g',
                'spark.executor.cores': '2',
                'spark.dynamicAllocation.enabled': 'true',
            },
            application_args=[
                '--input-path', 's3://raw-data/orders/{{ ds }}/',
                '--output-path', 's3://bronze/orders/',
                '--partition-date', '{{ ds }}',
            ],
        )

        ingest_products = SparkSubmitOperator(
            task_id='ingest_products_to_bronze',
            application='s3://spark-jobs/bronze/ingest_products.py',
            conn_id='spark_default',
            application_args=[
                '--input-path', 's3://raw-data/products/{{ ds }}/',
                '--output-path', 's3://bronze/products/',
            ],
        )

        ingest_customers = SparkSubmitOperator(
            task_id='ingest_customers_to_bronze',
            application='s3://spark-jobs/bronze/ingest_customers.py',
            conn_id='spark_default',
            application_args=[
                '--input-path', 's3://raw-data/customers/{{ ds }}/',
                '--output-path', 's3://bronze/customers/',
            ],
        )

    # ========================================================================
    # DATA QUALITY - Bronze Validation
    # ========================================================================
    @task(task_id='validate_bronze_data')
    def validate_bronze_data(**context):
        """Run Great Expectations validation on bronze data."""
        import great_expectations as ge
        
        context_ge = ge.get_context()
        
        validations = [
            {'batch': 'bronze_orders', 'suite': 'orders_expectations'},
            {'batch': 'bronze_products', 'suite': 'products_expectations'},
            {'batch': 'bronze_customers', 'suite': 'customers_expectations'},
        ]
        
        results = []
        for val in validations:
            result = context_ge.run_checkpoint(
                checkpoint_name=f"{val['batch']}_checkpoint"
            )
            results.append({
                'batch': val['batch'],
                'success': result.success,
                'statistics': result.run_results
            })
            
            if not result.success:
                raise ValueError(f"Data quality check failed for {val['batch']}")
        
        return results

    bronze_validation = validate_bronze_data()

    # ========================================================================
    # SILVER LAYER - dbt Transformations
    # ========================================================================
    with TaskGroup(group_id='silver_layer') as silver_layer:
        dbt_staging = DbtCloudRunJobOperator(
            task_id='dbt_staging_models',
            job_id=Variable.get('dbt_staging_job_id'),
            check_interval=30,
            timeout=3600,
        )

        dbt_intermediate = DbtCloudRunJobOperator(
            task_id='dbt_intermediate_models',
            job_id=Variable.get('dbt_intermediate_job_id'),
            check_interval=30,
            timeout=3600,
        )

        dbt_staging >> dbt_intermediate

    # ========================================================================
    # GOLD LAYER - Aggregations
    # ========================================================================
    with TaskGroup(group_id='gold_layer') as gold_layer:
        daily_sales = SparkSubmitOperator(
            task_id='aggregate_daily_sales',
            application='s3://spark-jobs/gold/daily_sales_agg.py',
            conn_id='spark_default',
            application_args=[
                '--date', '{{ ds }}',
                '--output-path', 's3://gold/daily_sales/',
            ],
        )

        customer_metrics = SparkSubmitOperator(
            task_id='compute_customer_metrics',
            application='s3://spark-jobs/gold/customer_metrics.py',
            conn_id='spark_default',
            application_args=[
                '--date', '{{ ds }}',
                '--output-path', 's3://gold/customer_metrics/',
            ],
        )

        product_performance = SparkSubmitOperator(
            task_id='compute_product_performance',
            application='s3://spark-jobs/gold/product_performance.py',
            conn_id='spark_default',
            application_args=[
                '--date', '{{ ds }}',
            ],
        )

    # ========================================================================
    # DATA EXPORT
    # ========================================================================
    @task(task_id='export_to_warehouse')
    def export_to_warehouse(**context):
        """Export gold layer data to data warehouse."""
        from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook
        
        hook = SnowflakeHook(snowflake_conn_id='snowflake_default')
        
        tables = ['daily_sales', 'customer_metrics', 'product_performance']
        for table in tables:
            hook.run(f"""
                COPY INTO {table}
                FROM @gold_stage/{table}/
                FILE_FORMAT = (TYPE = PARQUET)
                MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
            """)
        
        return {'exported_tables': tables}

    export_task = export_to_warehouse()

    # ========================================================================
    # NOTIFICATIONS
    # ========================================================================
    @task(task_id='send_success_notification')
    def send_notification(**context):
        """Send success notification."""
        message = f"""
        :white_check_mark: E-Commerce Pipeline Completed
        
        *Run Date:* {context['ds']}
        *Duration:* {context['dag_run'].end_date - context['dag_run'].start_date}
        """
        return message

    success_notification = SlackWebhookOperator(
        task_id='slack_success',
        http_conn_id='slack_webhook',
        message="{{ task_instance.xcom_pull(task_ids='send_success_notification') }}",
        trigger_rule='all_success',
    )

    end = EmptyOperator(task_id='end', trigger_rule='none_failed')

    # ========================================================================
    # TASK DEPENDENCIES
    # ========================================================================
    start >> data_sensors >> bronze_layer >> bronze_validation
    bronze_validation >> silver_layer >> gold_layer >> export_task
    export_task >> send_notification() >> success_notification >> end
