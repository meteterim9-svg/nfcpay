# NFC Pay

Flutter tabanlı NFC kart/etiket algılama uygulaması.

## Özellikler

- Koyu temalı, sade ve erişilebilir arayüz
- NFC donanım uygunluğunu kontrol etme
- NFC etiketini tek oturumda okuma
- Okuma zaman aşımı ve iptal desteği
- Okunan etiket kimliğini kullanıcıya gösterme
- PIN korumalı yerel uygulama kilidi

## Android

- Android cihazda NFC donanımı bulunmalı ve ayarlardan açık olmalı.
- Uygulama NFC iznini ister.
- NFC okuma yalnızca etiket kimliğini algılar.
- Kart numarası, banka, kart sahibi veya ödeme onayı üretmez.
- Para tahsilatı için lisanslı bir ödeme kuruluşunun SDK/API entegrasyonu, güvenli sunucu tarafı doğrulama ve gerekli sertifikasyonlar gerekir.

## APK

GitHub Actions, Android debug APK'sını derleyip artifact olarak yükler.
