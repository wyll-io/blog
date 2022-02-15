resource aws_s3_bucket bucket {
  bucket = "blog.wyll.io"
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

data aws_iam_policy_document policy {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:PutObject", "s3:ListBucket"]
    resources = ["arn:aws:s3:::blog.wyll.io/*"]
  }
}

resource aws_s3_bucket_policy bucket_policy {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.policy.json
}