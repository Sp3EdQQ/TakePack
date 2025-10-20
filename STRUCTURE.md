# TakePack - Struktura Projektu

## 📁 Architektura

Projekt został zorganizowany według wzorca **Clean Architecture** z podziałem na warstwy:

```
lib/
├── main.dart                    # Punkt wejścia aplikacji
├── models/                      # Modele danych
│   └── delivery_point.dart      # Model punktu dostawy
├── pages/                       # Ekrany aplikacji
│   └── map_page.dart           # Główny ekran z mapą
├── services/                    # Logika biznesowa i API
│   ├── api_service.dart        # REST API dla punktów dostawy
│   ├── routing_service.dart    # OSRM API dla tras drogowych
│   ├── location_service.dart   # Zarządzanie lokalizacją GPS
│   └── route_optimizer.dart    # Optymalizacja kolejności punktów (TSP)
├── widgets/                     # Komponenty UI wielokrotnego użytku
│   ├── route_info_bar.dart     # Pasek informacyjny (dystans, czas)
│   ├── loading_indicator.dart  # Wskaźnik ładowania
│   └── center_location_button.dart # Przycisk centrowania mapy
└── utils/                       # Funkcje pomocnicze
    ├── map_utils.dart          # Pomocnicze funkcje mapy (markery, polylines)
    └── proximity_manager.dart  # Detekcja bliskości punktów
```

## 🧩 Komponenty

### Models (`models/`)
**DeliveryPoint** - Model punktu dostawy
- `id`, `name`, `lat`, `lng`, `order`
- Metoda `fromJson()` do deserializacji

### Services (`services/`)

**ApiService** - Komunikacja z backendem
- Endpoint: `http://localhost:3000/points`
- Fallback: mockowe dane dla trybu offline

**RoutingService** - Routing drogowy (OSRM API)
- Pobiera trasy rzeczywiste (nie proste linie)
- Zwraca `RouteInfo` z dystansem i czasem

**RouteOptimizer** - Optymalizacja kolejności punktów
- Algorytm Nearest Neighbor (najbliższy sąsiad)
- Znajduje najkrótszą trasę (problem TSP)
- Zwraca punkty w optymalnej kolejności

**LocationService** - Zarządzanie GPS
- Obsługa uprawnień lokalizacji
- Stream pozycji z filtrem 5m
- Callback `onPositionUpdate`

### Widgets (`widgets/`)

**RouteInfoBar** - Nowoczesny pasek na górze
- Gradient niebieski
- Dystans i czas do pierwszego punktu
- Automatyczna aktualizacja

**LoadingIndicator** - Wskaźnik ładowania
- Pokazywany podczas pobierania tras
- Pozycja: prawy dolny róg (nad przyciskiem)

**CenterLocationButton** - Przycisk FAB
- Centruje mapę na użytkowniku
- Gradient niebieski z ikoną GPS

### Utils (`utils/`)

**MapUtils** - Funkcje pomocnicze mapy
- `createDeliveryMarkers()` - czerwone markery z numerami kolejności
- `createUserMarker()` - niebieski marker użytkownika
- `createPolylines()` - linie tras (niebieska, zielona)
- `getMapCenter()` - oblicza środek mapy

**ProximityManager** - Detekcja bliskości
- Próg: 30 metrów
- Dialog "Odbierz" przy zbliżeniu
- Zapamiętuje powiadomione punkty

## 🔄 Przepływ danych

```
main.dart
  └─> ApiService (baseUrl)
       └─> MapPage
            ├─> LocationService.initialize()
            ├─> ApiService.fetchPoints()
            ├─> RoutingService.getRouteInfo()
            │    └─> OSRM API
            └─> Render:
                 ├─> RouteInfoBar
                 ├─> LoadingIndicator
                 └─> CenterLocationButton
```

## 🎨 Konwencje nazewnictwa

- **Klasy**: `PascalCase` (np. `MapPage`, `RouteInfoBar`)
- **Pliki**: `snake_case.dart` (np. `map_page.dart`)
- **Prywatne pola**: `_leadingUnderscore` (np. `_currentPosition`)
- **Metody**: `camelCase` (np. `checkProximity`)
- **Stałe**: `camelCase` lub `SCREAMING_SNAKE_CASE`

## 📦 Zależności

```yaml
dependencies:
  flutter_map: ^6.2.1      # Rendering mapy
  latlong2: ^0.9.1         # Współrzędne geograficzne
  geolocator: ^9.0.2       # GPS tracking
  http: ^1.2.1             # HTTP requests
```

## 🚀 Uruchomienie

```bash
# Instalacja zależności
flutter pub get

# Uruchomienie na urządzeniu
flutter run -d <device_id>

# Build APK (Android)
flutter build apk
```

## 🧪 Testowanie

Kod jest gotowy do testowania jednostkowego:
- `LocationService` - mock Geolocator
- `ApiService` - mock http.Client
- `RoutingService` - mock OSRM responses
- `ProximityManager` - mock BuildContext

## 💡 Zalety obecnej struktury

✅ **Separacja odpowiedzialności** - każda klasa ma jedno zadanie
✅ **Testowalność** - łatwe mockowanie serwisów
✅ **Reużywalność** - widgety można używać w innych miejscach
✅ **Czytelność** - mały rozmiar plików (<150 linii)
✅ **Skalowalność** - łatwe dodawanie nowych funkcji
✅ **Utrzymanie** - zmiany w jednym miejscu nie psują innych

## 🔧 Rozszerzanie projektu

### Dodanie nowego widgetu:
1. Utwórz plik w `lib/widgets/nazwa_widgetu.dart`
2. Importuj w `map_page.dart`
3. Użyj w drzewie widgetów

### Dodanie nowego serwisu:
1. Utwórz plik w `lib/services/nazwa_service.dart`
2. Zdefiniuj interfejs (opcjonalnie abstrakcyjna klasa)
3. Wstrzyknij przez konstruktor do `MapPage`

### Dodanie nowej strony:
1. Utwórz plik w `lib/pages/nazwa_page.dart`
2. Dodaj routing w `main.dart` lub użyj Navigator
