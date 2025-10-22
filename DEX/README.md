# DEX OIDC Authentication Setup
Samsung Kubernetes Platform - Using Helm Charts

## 📋 סקירה כללית

DEX הוא OIDC (OpenID Connect) Provider שמאפשר:
- ✅ Single Sign-On (SSO) ל-Headlamp
- ✅ אימות משתמשים מרכזי
- ✅ RBAC אישי לכל משתמש
- ✅ Audit trail - מי עשה מה

## 🗂️ קבצים במערך

```
DEX/
├── dex-x.x.x.tgz                   # DEX Helm Chart
├── dex-values.yaml                 # DEX Helm values
├── dex-httproute.yaml              # HTTPRoute דרך Gateway (HTTPS אוטומטי!)
├── headlamp-oidc-values.yaml       # Headlamp עם OIDC (official way)
├── kube-apiserver-oidc-patch.yaml  # הוראות לעדכון API Server
├── rbac-admin-user.yaml            # הרשאות למשתמשים
└── README.md                       # הקובץ הזה
```

## 🚀 התקנה - צעד אחר צעד

### שלב 0: הורד Helm Charts
```bash
cd /home/master/samsung-kubernetes/DEX

# הורד DEX Helm chart
helm repo add dex https://charts.dexidp.io
helm pull dex/dex --version 0.18.0

# (או גרסה אחרת - בדוק עם: helm search repo dex)
```

### שלב 1: התקן DEX עם Helm
```bash
cd /home/master/samsung-kubernetes/DEX

# צור namespace
kubectl create namespace dex

# התקן DEX
helm install dex dex-*.tgz \
  -n dex \
  -f dex-values.yaml
```

### שלב 2: צור HTTPRoute ל-DEX
```bash
# HTTPRoute דרך Gateway (TLS אוטומטי!)
kubectl apply -f dex-httproute.yaml
```

### שלב 3: וודא שDEX רץ
```bash
# בדוק Pod
kubectl get pods -n dex

# בדוק HTTPRoute
kubectl get httproute -n dex

# בדוק לוגים
kubectl logs -n dex -l app=dex
```

### שלב 4: עדכן Headlamp עם OIDC
```bash
cd /home/master/samsung-kubernetes/Headlamp

# גבה את הקובץ הישן
cp headlamp-values.yaml headlamp-values.yaml.backup

# עדכן Headlamp
helm upgrade headlamp headlamp-0.34.0.tgz \
  -n headlamp \
  -f /home/master/samsung-kubernetes/DEX/headlamp-oidc-values.yaml
```

### שלב 5: הגדר RBAC למשתמשים
```bash
kubectl apply -f rbac-admin-user.yaml
```

### שלב 6: עדכן API Server (חשוב!)
```bash
# גבה את הקובץ המקורי
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml \
        /etc/kubernetes/manifests/kube-apiserver.yaml.backup

# ערוך את הקובץ
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml

# הוסף את השורות מתוך kube-apiserver-oidc-patch.yaml
# מתחת ל-spec.containers[0].command:
```

הוסף את השורות הבאות:
```yaml
- --oidc-issuer-url=https://dex.samsung.local
- --oidc-client-id=headlamp
- --oidc-username-claim=email
- --oidc-username-prefix=-
- --oidc-groups-claim=groups
- --oidc-groups-prefix=-
```

שמור וצא - ה-API server יעשה restart אוטומטי (1-2 דקות).

### שלב 7: הוסף ל-/etc/hosts
```bash
# על המחשב שלך (לא על השרת)
echo "192.168.33.157  dex.samsung.local" | sudo tee -a /etc/hosts
```

## ✅ בדיקה שהכל עובד

### 1. בדוק DEX
```bash
# DEX Pod
kubectl get pods -n dex
# צריך: Running, 1/1

# DEX Service
kubectl get svc -n dex
# צריך: ClusterIP, port 5556

# DEX HTTPRoute
kubectl describe httproute dex-route -n dex
# צריך: Accepted = True
```

### 2. בדוק HTTPS ל-DEX
```bash
curl -k https://dex.samsung.local/.well-known/openid-configuration
```
צריך לראות JSON עם:
```json
{
  "issuer": "https://dex.samsung.local",
  "authorization_endpoint": "https://dex.samsung.local/auth",
  ...
}
```

### 3. בדוק Headlamp
```bash
kubectl get pods -n headlamp
# Pod צריך להיות Running

kubectl logs -n headlamp -l app.kubernetes.io/name=headlamp --tail=20
# אין שגיאות OIDC
```

### 4. התחבר דרך דפדפן
1. פתח: `https://headlamp.samsung.local`
2. לחץ על **"Sign in"** או **"Login with OIDC"**
3. יעביר אותך ל-DEX
4. הכנס:
   - **Email:** `admin@samsung.local`
   - **Password:** `admin`
5. אישור ההרשאות
6. חזרה ל-Headlamp - מחובר! 🎉

## 👥 משתמשים זמינים (Static Users)

| Email | Password | הרשאות |
|-------|----------|--------|
| admin@samsung.local | admin | cluster-admin (מלא) |
| user@samsung.local | admin | view (קריאה בלבד) |

## 🔐 שינוי סיסמאות

```bash
# צור hash חדש לסיסמה
echo "newpassword" | htpasswd -BinC 10 admin | cut -d: -f2

# עדכן את dex-values.yaml עם ה-hash החדש
# ערוך את config.staticPasswords

# Upgrade DEX
helm upgrade dex dex-*.tgz -n dex -f dex-values.yaml
```

## 🔄 שדרוג ל-LDAP/AD (ייצור)

כאשר מוכנים, ערוך את `dex-values.yaml`:

1. הסר/הערה את `config.staticPasswords`
2. הסר הערה מ-`config.connectors` section
3. הגדר את פרטי ה-LDAP שלך
4. Upgrade:
   ```bash
   helm upgrade dex dex-*.tgz -n dex -f dex-values.yaml
   ```

## 🛠️ Troubleshooting

### DEX לא עולה
```bash
kubectl logs -n dex -l app.kubernetes.io/name=dex
kubectl describe pod -n dex -l app.kubernetes.io/name=dex

# בדוק Helm release
helm status dex -n dex
```

### Headlamp לא מתחבר ל-DEX
```bash
# בדוק redirect URI
kubectl logs -n headlamp -l app.kubernetes.io/name=headlamp | grep -i oidc

# בדוק ש-DEX נגיש
curl -k https://dex.samsung.local/.well-known/openid-configuration
```

### משתמש לא יכול להתחבר
```bash
# בדוק RBAC
kubectl get clusterrolebinding | grep oidc

# בדוק API Server logs
sudo tail -100 /var/log/pods/kube-system_kube-apiserver-*/kube-apiserver/*.log | grep -i oidc
```

### API Server לא מזהה OIDC tokens
```bash
# בדוק שה-flags נוספו
sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep oidc

# בדוק API Server Pod
kubectl get pods -n kube-system | grep apiserver
```

## 📚 מידע נוסף

- [DEX Documentation](https://dexidp.io/docs/)
- [Kubernetes OIDC](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#openid-connect-tokens)
- [Headlamp OIDC](https://headlamp.dev/docs/latest/installation/#oidc)

## 🎯 הארכיטקטורה

```
משתמש
  ↓
https://headlamp.samsung.local
  ↓
Click "Login with OIDC"
  ↓
Redirect to https://dex.samsung.local
  ↓
DEX Authentication
  ↓ (validates user)
Static Users / LDAP / AD
  ↓
OIDC Token
  ↓
Back to Headlamp
  ↓
Headlamp → Kubernetes API (with token)
  ↓
API Server validates token with DEX
  ↓
RBAC check (admin@samsung.local → cluster-admin)
  ↓
Access granted! 🎉
```

