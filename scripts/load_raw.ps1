# Loads the three H&M raw files from a local folder into BigQuery.
# Raw data is never committed (Kaggle competition rules, section 7B).
# Usage: .\scripts\load_raw.ps1            (defaults below)
#        .\scripts\load_raw.ps1 -RawDir "D:\hm"

param(
  [string]$RawDir  = "C:\data\hm-raw",
  [string]$Project = "fashion-cx",
  [string]$Dataset = "hm_raw"
)

$ErrorActionPreference = "Stop"
function Assert-Ok($step) { if ($LASTEXITCODE -ne 0) { throw "Failed: $step" } }

Push-Location $RawDir
try {
  # articles: all STRING (IDs keep leading zeros; typing happens in Dataform staging)
  $articlesSchema = "article_id:STRING,product_code:STRING,prod_name:STRING,product_type_no:STRING,product_type_name:STRING,product_group_name:STRING,graphical_appearance_no:STRING,graphical_appearance_name:STRING,colour_group_code:STRING,colour_group_name:STRING,perceived_colour_value_id:STRING,perceived_colour_value_name:STRING,perceived_colour_master_id:STRING,perceived_colour_master_name:STRING,department_no:STRING,department_name:STRING,index_code:STRING,index_name:STRING,index_group_no:STRING,index_group_name:STRING,section_no:STRING,section_name:STRING,garment_group_no:STRING,garment_group_name:STRING,detail_desc:STRING"
  bq load --project_id=$Project --location=US --source_format=CSV --skip_leading_rows=1 --allow_quoted_newlines --replace "$Dataset.articles" .\articles.csv $articlesSchema
  Assert-Ok "articles"

  # customers: all STRING (FN/Active arrive as 1.0 or blank; age has blanks)
  $customersSchema = "customer_id:STRING,FN:STRING,Active:STRING,club_member_status:STRING,fashion_news_frequency:STRING,age:STRING,postal_code:STRING"
  bq load --project_id=$Project --location=US --source_format=CSV --skip_leading_rows=1 --replace "$Dataset.customers" .\customers.csv $customersSchema
  Assert-Ok "customers"

  # transactions: typed at load to reduce storage; loaded from gzip to cut upload size
  $transactionsSchema = "t_dat:DATE,customer_id:STRING,article_id:STRING,price:FLOAT,sales_channel_id:INTEGER"
  bq load --project_id=$Project --location=US --source_format=CSV --skip_leading_rows=1 --replace "$Dataset.transactions" .\transactions_train.csv.gz $transactionsSchema
  Assert-Ok "transactions"

  # Verify: expected articles 105,542 / customers 1,371,980 / transactions 31,788,324
  bq query --project_id=$Project --location=US --use_legacy_sql=false "SELECT table_id, row_count, ROUND(size_bytes / POW(1024, 3), 2) AS size_gb FROM $Dataset.__TABLES__ ORDER BY size_bytes DESC"
  Assert-Ok "verify"
}
finally {
  Pop-Location
}
