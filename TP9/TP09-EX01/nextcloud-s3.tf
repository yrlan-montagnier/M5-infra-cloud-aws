data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "nextcloud_bucket" {
  bucket = "${local.name}-nextcloud" # Sans variable pour les minuscules

  tags = {
    Name = "${local.name}-nextcloud"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "nextcloud_bucket_sse" {
  bucket = aws_s3_bucket.nextcloud_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "nextcloud_bucket_policy" {
  bucket = aws_s3_bucket.nextcloud_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowTerraformAdmin"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::134400125759:user/users/ynov/ymontagnier"
        }
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketPolicy",
          "s3:PutBucketPolicy"
        ]
        Resource = aws_s3_bucket.nextcloud_bucket.arn
      },
      {
        Sid    = "DenyTerraformDataAccess"
        Effect = "Deny"
        Principal = {
          AWS = "arn:aws:iam::134400125759:user/users/ynov/ymontagnier"
        }
        Action = [
          "s3:GetObject*",
          "s3:PutObject*",
          "s3:DeleteObject*"
        ]
        Resource = "${aws_s3_bucket.nextcloud_bucket.arn}/*"
      },
      {
        Sid    = "AllowEC2Access"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.nextcloud_role.arn
        }
        Action = [
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        Resource = [
          aws_s3_bucket.nextcloud_bucket.arn,
          "${aws_s3_bucket.nextcloud_bucket.arn}/*"
        ]
      },
      {
        Sid    = "DenyOtherActionsForNextcloudRole"
        Effect = "Deny"
        Principal = {
          AWS = aws_iam_role.nextcloud_role.arn
        }
        NotAction = [
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        Resource = [
          aws_s3_bucket.nextcloud_bucket.arn,
          "${aws_s3_bucket.nextcloud_bucket.arn}/*"
        ]
      }
    ]
  })
}

output "nextcloud_bucket" {
  value = aws_s3_bucket.nextcloud_bucket.bucket
}