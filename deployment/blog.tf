resource aws_s3_bucket bucket {
  bucket = "blog.wyll.io"
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

data github_policy policy {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.bucket.arn}/*"]
  }
}