# دليل النشر إلى AWS ECS 🚀

## المتطلبات الأساسية

### 1️⃣ إضافة GitHub Secrets
أذهب إلى: **Settings > Secrets and variables > Actions**

أضف هذه المتغيرات:

| المتغير | الوصف | مثال |
|--------|-------|------|
| `AWS_ACCESS_KEY_ID` | مفتاح الوصول AWS | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | المفتاح السري AWS | `wJal...` |

---

## إعدادات AWS المطلوبة

### 2️⃣ إنشاء ECR Repository

```bash
aws ecr create-repository \
  --repository-name hlme89-repo \
  --region us-east-1
```

**النتيجة:** ستحصل على رابط مثل:
```
xxx.dkr.ecr.us-east-1.amazonaws.com/hlme89-repo
```

---

### 3️⃣ إنشاء CloudWatch Log Group

```bash
aws logs create-log-group \
  --log-group-name /ecs/hlme89 \
  --region us-east-1
```

---

### 4️⃣ إنشاء ECS Cluster

```bash
aws ecs create-cluster \
  --cluster-name hlme89-cluster \
  --region us-east-1
```

---

### 5️⃣ إنشاء IAM Roles

#### أ) Role للتنفيذ (ecsTaskExecutionRole):

```bash
aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ecs-tasks.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'
```

ثم أضف السياسة:

```bash
aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

#### ب) Role لتطبيقك (ecsTaskRole):

```bash
aws iam create-role \
  --role-name ecsTaskRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ecs-tasks.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'
```

---

### 6️⃣ تسجيل Task Definition

**ملاحظة:** استبدل `ACCOUNT_ID` برقم حسابك AWS

```bash
aws ecs register-task-definition \
  --cli-input-json file://.aws/task-definition.json \
  --region us-east-1
```

---

### 7️⃣ إنشاء VPC (إذا لم تكن موجودة)

```bash
# إنشاء VPC
aws ec2 create-vpc --cidr-block 10.0.0.0/16

# إنشاء Subnet
aws ec2 create-subnet \
  --vpc-id vpc-xxx \
  --cidr-block 10.0.1.0/24

# إنشاء Security Group
aws ec2 create-security-group \
  --group-name hlme89-sg \
  --description "Security group for hlme89" \
  --vpc-id vpc-xxx

# السماح بالوصول على منفذ 3000
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxx \
  --protocol tcp \
  --port 3000 \
  --cidr 0.0.0.0/0
```

---

### 8️⃣ إنشاء ECS Service

```bash
aws ecs create-service \
  --cluster hlme89-cluster \
  --service-name hlme89-service \
  --task-definition hlme89-task:1 \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={
    subnets=[subnet-xxx],
    securityGroups=[sg-xxx],
    assignPublicIp=ENABLED
  }" \
  --region us-east-1
```

---

## عملية النشر التلقائي 🔄

عند الدفع إلى فرع `main`:

```
┌─────────────────────┐
│  git push main      │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│ GitHub Actions      │
│ - Checkout code     │
│ - Build Docker      │
│ - Push to ECR       │
│ - Update Task Def   │
│ - Deploy to ECS     │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│ Your App Running! 🎉│
└─────────────────────┘
```

---

## المراقبة والتحقق 📊

### عرض سجلات التطبيق:
```bash
aws logs tail /ecs/hlme89 --follow
```

### عرض حالة الخدمة:
```bash
aws ecs describe-services \
  --cluster hlme89-cluster \
  --services hlme89-service
```

### عرض المهام الجارية:
```bash
aws ecs list-tasks \
  --cluster hlme89-cluster \
  --service-name hlme89-service
```

### الوصول إلى التطبيق:
```
http://your-load-balancer-url:3000
```

---

## استكشاف الأخطاء 🐛

### ❌ فشل البناء
- **الحل:** تأكد من وجود `Dockerfile` و `package.json`
- تحقق من صحة الصيغة

### ❌ فشل الدفع إلى ECR
- **الحل:** تحقق من:
  - صحة `AWS_ACCESS_KEY_ID` و `AWS_SECRET_ACCESS_KEY`
  - وجود Repository في ECR
  - صلاحيات IAM

### ❌ فشل النشر على ECS
- **الحل:**
  - تأكد من وجود Subnets و Security Groups
  - تحقق من Task Definition
  - عرض السجلات: `aws logs tail /ecs/hlme89 --follow`

### ❌ التطبيق لا يستجيب
- **الحل:**
  - تحقق من Port (3000)
  - تأكد من أن الصورة تحتوي على `npm start`
  - عرض السجلات

---

## الملفات المطلوبة ✅

```
hlme89/
├── .github/
│   ├── workflows/
│   │   └── aws.yml ✅ (موجود)
│   └── DEPLOYMENT_GUIDE.md ✅ (هذا الملف)
├── .aws/
│   └── task-definition.json ✅ (موجود)
├── Dockerfile ✅ (موجود)
├── package.json ✅ (موجود)
├── package-lock.json
└── src/
    └── ... (ملفات التطبيق)
```

---

## روابط مفيدة 🔗

- [AWS ECS Docs](https://docs.aws.amazon.com/ecs/)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/)
- [GitHub Actions AWS](https://github.com/aws-actions)
- [Docker Documentation](https://docs.docker.com/)

---

## ملخص الخطوات السريعة ⚡

```bash
# 1. أضف Secrets إلى GitHub
# Settings > Secrets and variables > Actions

# 2. قم بتشغيل أوامر AWS CLI أعلاه

# 3. ادفع التغييرات
git add .
git commit -m "Setup AWS ECS deployment"
git push origin main

# 4. شاهد العملية تعمل 🚀
# اذهب إلى: https://github.com/hlme7788145-a11y/hlme89/actions
```

---

**تم إنشاء هذا الدليل بتاريخ:** 2026-06-10
**الحالة:** ✅ جاهز للإنتاج
