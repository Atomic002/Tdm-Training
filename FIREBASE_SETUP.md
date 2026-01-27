# 🔥 Firebase Setup - TDM Training

Bu qo'llanma TDM Training ilovasi uchun Firebase'ni to'liq sozlashni ko'rsatadi.

---

## 📋 1. Firebase Console Setup

### 1.1 Firebase Project yaratish
1. [Firebase Console](https://console.firebase.google.com/) ga kiring
2. "Add Project" → Project nomini kiriting (masalan: "TDM Training")
3. Google Analytics: **Enable** (tavsiya etiladi)
4. Projectni yarating

### 1.2 Android App qo'shish
1. Project Dashboard → ⚙️ Settings → **Add app** → Android
2. **Android package name**: `com.rahmatullo.tdm_training`
3. **google-services.json** yuklab, `android/app/` papkaga joylashtiring
4. **Continue** → **Next** → **Continue to console**

---

## 🔐 2. Firebase Authentication

1. **Build** → **Authentication** → **Get Started**
2. **Sign-in method** → **Google** → **Enable**
3. Support email tanlang → **Save**

### SHA-1 Fingerprint (MUHIM!)
Google Sign-In ishlashi uchun SHA-1 kerak:

```bash
cd android
./gradlew signingReport
```

Output'dan **SHA-1** ni ko'chiring:
```
SHA1: AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:00:AA:BB:CC:DD
```

Firebase Console → ⚙️ Settings → **Add fingerprint** → SHA-1 ni paste qiling

---

## 📊 3. Firestore Database

### 3.1 Database yaratish
1. **Build** → **Firestore Database** → **Create database**
2. **Start in production mode** → **Next**
3. Location: **asia-east1** (yoki yaqin region) → **Enable**

### 3.2 Security Rules Deploy qilish

**Option 1: Firebase Console orqali**
1. **Firestore Database** → **Rules** tab
2. `firestore.rules` faylidagi barcha kodni ko'chiring
3. **Publish** tugmasini bosing ✅

**Option 2: Firebase CLI orqali**
```bash
firebase login
firebase init firestore
firebase deploy --only firestore:rules
```

### 3.3 Firestore Indexes Deploy qilish (MUHIM!)

Vazifalar to'g'ri ishlashi uchun **Composite Indexes** kerak!

**Option 1: Firebase Console orqali**
1. **Firestore Database** → **Indexes** tab
2. **Add Index** tugmasini bosing
3. **Collection ID**: `tasks`
4. Field #1: `isActive` (Ascending)
5. Field #2: `order` (Ascending)
6. **Create** tugmasini bosing ✅

**Option 2: Firebase CLI orqali (Tavsiya etiladi)**
```bash
firebase login
firebase init firestore  # firestore.indexes.json faylini tanlang
firebase deploy --only firestore:indexes
```

`firestore.indexes.json` fayli loyihada allaqachon mavjud va to'liq sozlangan.

**MUHIM**: Index yaratish 5-10 daqiqa vaqt olishi mumkin. Console'da "Building" holatini ko'rasiz. To'liq tayyor bo'lguncha kuting!

---

## 🎯 4. Firestore Collections yaratish

### 4.1 Settings Collection

**Path:** `settings/app`

```json
{
  "telegramBotToken": "1234567890:ABCdefGHIjklMNOpqrsTUVwxyz",
  "telegramChannelUsername": "https://t.me/+ENJzzXqorMQzNDM6",
  "instagramPageUrl": "https://instagram.com/your_page",
  "maxDailyAds": 10,
  "maxDailyGames": 20,
  "coinsPerAd": 5,
  "referralRewardForReferrer": 100,
  "referralBonusForReferred": 50
}
```

**Field Types:**
- `telegramBotToken`: **string**
- `telegramChannelUsername`: **string**
- `instagramPageUrl`: **string**
- `maxDailyAds`: **number**
- `maxDailyGames`: **number**
- `coinsPerAd`: **number**
- `referralRewardForReferrer`: **number**
- `referralBonusForReferred`: **number**

### 4.2 Tasks Collection

**Path:** `tasks/[Auto-ID]`

**Telegram Vazifasi:**
```json
{
  "type": "telegramSubscribe",
  "title": "Telegram kanalga obuna bo'ling",
  "description": "Telegram kanalimizga obuna bo'lib 50 coin oling",
  "reward": 50,
  "isActive": true,
  "link": "https://t.me/+ENJzzXqorMQzNDM6",
  "iconName": "star",
  "order": 1,
  "dailyLimit": 1,
  "requiresVerification": false,
  "createdAt": [TIMESTAMP],
  "updatedAt": [TIMESTAMP]
}
```

**Instagram Vazifasi:**
```json
{
  "type": "instagramFollow",
  "title": "Instagram'da follow qiling",
  "description": "Instagram sahifamizga follow bo'lib 30 coin oling",
  "reward": 30,
  "isActive": true,
  "link": "https://instagram.com/your_page",
  "iconName": "star",
  "order": 2,
  "dailyLimit": 1,
  "requiresVerification": false,
  "createdAt": [TIMESTAMP],
  "updatedAt": [TIMESTAMP]
}
```

**Field Types:**
- `type`: **string** - Quyidagilardan biri:
  - `telegramSubscribe`
  - `instagramFollow`
  - `youtubeSubscribe`
  - `youtubeWatch`
  - `tikTokFollow`
  - `facebookLike`
  - `dailyLogin`
  - `inviteFriend`
  - `watchAd`
  - `playGame`
  - `appDownload`
  - `shareApp`
  - `rateApp`
- `title`: **string**
- `description`: **string**
- `reward`: **number**
- `isActive`: **boolean**
- `link`: **string** (ixtiyoriy)
- `iconName`: **string**
- `order`: **number**
- `dailyLimit`: **number**
- `requiresVerification`: **boolean**
- `createdAt`: **timestamp**
- `updatedAt`: **timestamp**

---

## 👤 5. Admin User yaratish

### 5.1 Birinchi login
1. Ilovani ishga tushiring
2. Google Sign-In bilan login qiling
3. Firestore → **users** collection → **sizning UID**

### 5.2 Admin qilish
Document'ni oching va quyidagi field qo'shing:
```json
{
  "isAdmin": true
}
```

---

## 🤖 6. Telegram Bot Setup (Ixtiyoriy)

### 6.1 Bot yaratish
1. Telegram'da [@BotFather](https://t.me/botfather) ga yozing
2. `/newbot` buyrug'ini yuboring
3. Bot nomini kiriting
4. Username kiriting (masalan: `tdm_training_bot`)
5. **Token** ni ko'chiring: `1234567890:ABCdefGHIjklMNOpqrsTUVwxyz`

### 6.2 Bot'ni kanal admin qilish
1. Telegram kanalingizga o'ting
2. **Channel Info** → **Administrators** → **Add Administrator**
3. Botingizni qidiring va admin qiling

### 6.3 Token'ni Firestore'ga qo'shish
`settings/app` document'dagi `telegramBotToken` field'ga token'ni qo'ying.

---

## ✅ 7. Test qilish

### 7.1 Authentication test
```bash
flutter run
```
- Google Sign-In ishlashini tekshiring
- Firestore → **users** collection'da user yaratilganini tekshiring

### 7.2 Tasks test
- Ilovada **Vazifalar** sahifasiga o'ting
- Vazifalar ko'rinishini tekshiring
- Biror vazifani bajaring va coin oling

### 7.3 Admin Panel test
- `isAdmin: true` qo'shganingizdan keyin
- Ilovada **Admin Panel** tugmasini bosing
- Vazifalar, Userlar, Exchangelar ko'rinishini tekshiring

---

## 🐛 8. Troubleshooting

### Vazifalar ko'rinmayapti
**Console debug output ko'ring:**
```
DEBUG: ========== VAZIFALARNI YUKLASH BOSHLANDI ==========
DEBUG: User UID: ...
DEBUG: Firestore'dan X ta vazifa topildi
```

**Agar "0 ta vazifa topildi" ko'rsatsa:**
1. Firestore Console → **tasks** collection bor-yo'qligini tekshiring
2. `isActive: true` ekanligini tekshiring
3. `type` field **string** formatida (`"telegramSubscribe"`) ekanligini tekshiring
4. **Composite Index** yaratilganini tekshiring (3.3-bo'limga qarang)

**Agar console'da "Composite index yo'q, fallback query" ko'rsatsa:**
```
DEBUG [FirestoreService]: ⚠️ Composite index yo'q, fallback query ishlatilmoqda...
DEBUG [FirestoreService]: Index xatosi: ...
```
Bu normal! Ilova ishlaydi, lekin Firestore Index yaratish tavsiya etiladi:
- Firebase Console → Indexes → Add Index (3.3-bo'limga qarang)
- Yoki `firebase deploy --only firestore:indexes` ishlatiladi

**Agar PERMISSION_DENIED xatosi chiqsa:**
1. Security Rules to'g'ri publish qilganingizni tekshiring
2. Google Sign-In qilganingizni tekshiring
3. `firebase.auth != null` ekanligini tekshiring

### Exchange PERMISSION_DENIED
- Security Rules'da `/users/{userId}/exchanges` **subcollection** path bo'lishi kerak
- Root `/exchanges` emas!

### UC so'rovlar admin panel'da ko'rinmayapti
**Muammo:** UC almashish so'rovlari yuboriladi, lekin Admin Panel → UC so'rovlar bo'sh.

**Console debug output ko'ring:**
```
DEBUG [Exchange]: ========== UC ALMASHTIRISH BOSHLANDI ==========
DEBUG [Exchange]: User UID: ...
DEBUG [Exchange]: Coins: 100, UC: 10
DEBUG [Exchange]: ✓ 100 coin sarflandi
DEBUG [Exchange]: ✓ Exchange yaratildi, ID: xyz123
```

**Agar so'rov yaratilgan bo'lsa, admin panel'da ko'ring:**
```
DEBUG [Admin-Exchange]: ========== PENDING UC SO'ROVLAR YUKLASH BOSHLANDI ==========
DEBUG [Admin-Exchange]: Jami 5 ta user topildi
DEBUG [Admin-Exchange]: 5 ta userdan jami 2 ta pending exchange topildi
```

**Agar "0 ta pending exchange" ko'rsatsa:**
1. Firestore Console → users → [UserID] → exchanges subcollection'ni tekshiring
2. Exchange document'da `status: "pending"` ekanligini tekshiring
3. **Composite Index** (exchanges: status + createdAt) yaratilganini tekshiring

**Agar index xatosi chiqsa:**
```
DEBUG [Admin-Exchange]: ⚠️ User ... uchun query xatosi (index yo'q bo'lishi mumkin)
DEBUG [Admin-Exchange]: Fallback: User ... : 1 ta pending exchange (in-memory filter)
```
Bu holda ilova ishlaydi (fallback mode), lekin indexni yaratish tavsiya etiladi:
- `firebase deploy --only firestore:indexes`
- Yoki Firebase Console → Indexes → Manual index creation

### Google Sign-In ishlamayapti
1. SHA-1 fingerprint qo'shganingizni tekshiring
2. `google-services.json` fayli to'g'ri joyda ekanligini tekshiring
3. Package name to'g'ri ekanligini (`com.rahmatullo.tdm_training`) tekshiring

---

## 📱 9. Console Debug Output

Vazifalar sahifasiga o'tganda quyidagi DEBUG xabarlar chiqishi kerak:

**Agar Composite Index mavjud bo'lsa:**
```
I/flutter (12345): DEBUG: ========== VAZIFALARNI YUKLASH BOSHLANDI ==========
I/flutter (12345): DEBUG: User UID: abc123xyz...
I/flutter (12345): DEBUG [FirestoreService]: tasks collection dan o'qish boshlandi...
I/flutter (12345): DEBUG [FirestoreService]: 2 ta faol vazifa topildi (index bilan)
I/flutter (12345): DEBUG: Firestore'dan 2 ta vazifa topildi
I/flutter (12345): DEBUG: ✓ Vazifa #1 - Telegram kanalga obuna bo'ling
I/flutter (12345): DEBUG:   Type: TaskType.telegramSubscribe, Active: true, Reward: 50
I/flutter (12345): DEBUG:   Link: https://t.me/+ENJzzXqorMQzNDM6
I/flutter (12345): DEBUG: ✓ Vazifa #2 - Instagram'da follow qiling
I/flutter (12345): DEBUG:   Type: TaskType.instagramFollow, Active: true, Reward: 30
I/flutter (12345): DEBUG:   Link: https://instagram.com/your_page
I/flutter (12345): DEBUG: 0 ta vazifa bugun bajarilgan
I/flutter (12345): DEBUG: User ma'lumoti yuklandi: Axi Zava
I/flutter (12345): DEBUG: ========== YUKLASH TUGADI ==========
```

**Agar Index yo'q bo'lsa (fallback mode):**
```
I/flutter (12345): DEBUG: ========== VAZIFALARNI YUKLASH BOSHLANDI ==========
I/flutter (12345): DEBUG: User UID: abc123xyz...
I/flutter (12345): DEBUG [FirestoreService]: tasks collection dan o'qish boshlandi...
I/flutter (12345): DEBUG [FirestoreService]: ⚠️ Composite index yo'q, fallback query ishlatilmoqda...
I/flutter (12345): DEBUG [FirestoreService]: Index xatosi: [cloud_firestore/failed-precondition] ...
I/flutter (12345): DEBUG [FirestoreService]: 2 ta faol vazifa topildi (fallback)
I/flutter (12345): DEBUG [FirestoreService]: Vazifalar in-memory sort qilindi
I/flutter (12345): DEBUG: Firestore'dan 2 ta vazifa topildi
I/flutter (12345): DEBUG: ✓ Vazifa #1 - Telegram kanalga obuna bo'ling
I/flutter (12345): DEBUG:   Type: TaskType.telegramSubscribe, Active: true, Reward: 50
I/flutter (12345): DEBUG: 0 ta vazifa bugun bajarilgan
I/flutter (12345): DEBUG: User ma'lumoti yuklandi: Axi Zava
I/flutter (12345): DEBUG: ========== YUKLASH TUGADI ==========
```

**MUHIM:** Fallback mode'da ham ilova to'g'ri ishlaydi, faqat biroz sekinroq bo'ladi. Index yaratish tavsiya etiladi!

**Agar bu xabarlar chiqmasa:**
1. Console filter'da `package:com.rahmatullo.tdm_training` yozilganini tekshiring
2. Logcat'da `flutter` tag'i enabled ekanligini tekshiring
3. Vazifalar sahifasiga haqiqatan o'tganingizni tekshiring

---

## 🎉 10. Tayyor!

Agar barcha qadamlarni bajarsangiz:
- ✅ Users login qila oladi
- ✅ Vazifalar ko'rinadi va bajariladi
- ✅ Coinlar to'planadi
- ✅ UC almashtirish ishlaydi
- ✅ Admin panel ishlaydi
- ✅ Leaderboard ko'rsatiladi

**Muammo bo'lsa, console output screenshot qilib yuboring!** 🚀
