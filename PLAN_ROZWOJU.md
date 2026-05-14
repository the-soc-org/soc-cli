# Plan rozwoju `soc-cli`

## Cel
Rozwinąć `soc-cli` jako stabilne, wieloplatformowe CLI do zarządzania kursami SoC, z naciskiem na jakość UX, bezpieczeństwo operacji administracyjnych i łatwość utrzymania.

## Założenia strategiczne
- Zachować architekturę komend prefiksowanych platformą (`soc-<platform>-<cmd>`).
- Utrzymać kompatybilność z obecnym przepływem `gh soc ...`.
- Priorytetyzować bezpieczeństwo operacji destrukcyjnych (`delete`, `unsync`, `close`).
- Ułatwić adopcję narzędzia przez lepszą dokumentację i diagnostykę.

## Etap 1 — Stabilizacja fundamentów (najwyższy priorytet)

### 1.1 Walidacja i precheck
- [ ] Rozszerzyć `precheck` o pełną walidację konfiguracji (`user_config.sh`, `source_config.sh`, `system_config.sh`).
- [ ] Dodać czytelne komunikaty błędów z podpowiedzią naprawy.
- [ ] Dodać tryb `--verbose` oraz kod wyjścia per klasa błędu.

### 1.2 Bezpieczeństwo operacji
- [ ] Wymusić dodatkowe potwierdzenia dla `delete`, `unsync`, `close`.
- [ ] Dodać tryb `--dry-run` dla komend modyfikujących stan organizacji/repo.
- [ ] Wprowadzić centralną obsługę rollbacku/częściowego niepowodzenia.

### 1.3 Spójność CLI
- [ ] Ujednolicić format helpa i przykładów dla wszystkich komend.
- [ ] Ustandaryzować kody wyjścia i prefiksy logów (`INFO/WARN/ERROR`).
- [ ] Dodać walidację argumentów wejściowych na poziomie wrapperów komend.

## Etap 2 — Utrzymanie i jakość kodu

### 2.1 Testy i walidacja techniczna
- [ ] Dodać testy jednostkowe kluczowych funkcji bibliotek (`soc-lib.sh`, `soc-lib-gh.sh`).
- [ ] Dodać testy smoke dla głównych komend (`init`, `precheck`, `sync`, `open`, `assign`).
- [ ] Dodać automatyczne uruchamianie walidacji shellowej (np. lint + test) w CI.

### 2.2 Refaktoryzacja i porządki
- [ ] Rozdzielić funkcje o wysokiej złożoności na mniejsze moduły.
- [ ] Ujednolicić nazewnictwo funkcji i stałych konfiguracyjnych.
- [ ] Zmniejszyć duplikację logiki pomiędzy komendami administracyjnymi.

## Etap 3 — Użyteczność dla prowadzących kurs

### 3.1 Lepsza obserwowalność
- [ ] Rozszerzyć `status` o podsumowanie: liczba repo, przypisań, zaproszeń i niezgodności.
- [ ] Rozszerzyć `log` o metadane uruchomienia (czas, użytkownik, wersja CLI).
- [ ] Dodać prosty eksport raportów do CSV/JSON z jednym formatem schematu.

### 3.2 Ergonomia pracy
- [ ] Dodać interaktywne potwierdzenia z możliwością pominięcia (`--yes`) dla automatyzacji.
- [ ] Dodać czytelne komunikaty postępu dla dłuższych operacji (`sync`, `open`).
- [ ] Dodać szybkie komendy diagnostyczne (`soc doctor` / rozszerzony `precheck`).

## Etap 4 — Rozszerzalność platformowa

### 4.1 Interfejs platform
- [ ] Zdefiniować kontrakt dla nowych platform (`soc-<platform>-*` + wspólne API funkcji).
- [ ] Przygotować szablon startowy nowej platformy (minimalny zestaw komend + dokumentacja).
- [ ] Dodać test kompatybilności międzyplatformowej dla dispatcher-a `soc`.

### 4.2 Wersjonowanie i release
- [ ] Wprowadzić semantyczne wersjonowanie i changelog wydania.
- [ ] Dodać proces release z checklistą kompatybilności i migracji.

## Etap 5 — Dokumentacja i adopcja

### 5.1 Dokumentacja użytkownika
- [ ] Przebudować README pod scenariusz „quick start do pierwszego kursu”.
- [ ] Dodać sekcję „najczęstsze problemy i rozwiązania”.
- [ ] Dodać pełną tabelę komend z parametrami i przykładami.

### 5.2 Dokumentacja techniczna
- [ ] Rozszerzyć ADR o standard tworzenia nowych komend i modułów.
- [ ] Dodać przewodnik contributorski: lokalny workflow, testy, standard zmian.

## Proponowany backlog Issue (do utworzenia i przypisania)

### Epic A — Stabilność i bezpieczeństwo
- [ ] ISSUE: Rozszerzony precheck walidujący wszystkie pliki konfiguracyjne.
- [ ] ISSUE: `--dry-run` dla komend modyfikujących stan zasobów GitHub.
- [ ] ISSUE: Dodatkowe potwierdzenia i mechanizm bezpiecznika dla `delete/unsync`.
- [ ] ISSUE: Standaryzacja kodów wyjścia i formatu błędów.

### Epic B — Jakość i utrzymanie
- [ ] ISSUE: Testy jednostkowe dla `soc-lib.sh`.
- [ ] ISSUE: Testy jednostkowe dla `soc-lib-gh.sh`.
- [ ] ISSUE: Testy smoke dla ścieżki `init -> precheck -> sync`.
- [ ] ISSUE: Integracja lint/test w CI.

### Epic C — UX i operacyjność
- [ ] ISSUE: Rozbudowany `status` z metrykami kursu.
- [ ] ISSUE: Ujednolicony, czytelny output logów i tryb verbose.
- [ ] ISSUE: Raport eksportu CSV/JSON.
- [ ] ISSUE: Quick diagnostics (`doctor`) dla prowadzących.

### Epic D — Rozszerzalność i release
- [ ] ISSUE: Kontrakt interfejsu platformowego dla `soc-<platform>-*`.
- [ ] ISSUE: Szablon implementacji nowej platformy.
- [ ] ISSUE: SemVer + changelog + proces release.

## Kryteria gotowości (Definition of Done)
- [ ] Każde zadanie ma kryteria akceptacji i właściciela.
- [ ] Zmiany są pokryte testami adekwatnymi do ryzyka.
- [ ] Dokumentacja użytkowa i techniczna jest zaktualizowana.
- [ ] Operacje wysokiego ryzyka mają zabezpieczenia i czytelny rollback.
- [ ] Brak regresji dla podstawowych komend (`init`, `sync`, `open`, `assign`, `status`).

