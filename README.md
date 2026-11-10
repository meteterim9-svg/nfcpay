# nfcpay

İnternetsiz çalışan, NFC ile ödeme yapan eğlence amaçlı Flutter uygulaması.

## Ne yapar

1. Açılışta 4 haneli PIN sorar. İlk açılışta PIN oluşturulur (iki kez girilir), sonraki açılışlarda aynı PIN ile girilir. Sadece sayı tuşları vardır.
2. Ödeme ekranında tutar girilir.
3. "Ödeme yap" denince cihazda NFC'nin açık olup olmadığı kontrol edilir.
4. "Kartı okut" ekranı çıkar; telefon karta yaklaştırılır.
5. Kart okunur, 4-5 saniyelik işlem animasyonundan sonra "Ödeme başarılı" ekranı gelir.

İşlem sonunda kart numarası (son 4 hane), kart sahibi, banka, son kullanma tarihi ve işlem numarası gösterilir.

## Tasarım

Koyu lacivert zemin üzerine mavi → pembe → yeşil geçişli gradyanlar: başlıklar, PIN noktaları, butonlar ve başarı ekranı.

## Önemli

Bu bir **demonstrasyondur**. Hiçbir para transferi yapmaz, hiçbir bankaya ya da ödeme sistemine bağlanmaz, hiçbir kart verisi kaydetmez. Ekranda görünen kart ve banka bilgileri tamamen kurgudur.

Uygulama hiçbir ağ izni istemez ve hiçbir yere veri göndermez.

## APK nasıl alınır

Hazır APK `orvexa` deposunda olduğu gibi Actions > "APK derle" akışıyla üretilir. Bu depoya iş akışı eklenirken GitHub jetonu yeterli izne sahip değildi; eklemek için repoya `.github/workflows/build.yml` dosyasını `orvexa` deposundaki haliyle eklemek yeterli.
