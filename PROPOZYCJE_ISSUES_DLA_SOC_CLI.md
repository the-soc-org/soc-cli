# Propozycje Issues dla soc-cli

## Epic A — Stabilność i bezpieczeństwo
- [ ] ISSUE: Rozszerzony precheck walidujący wszystkie pliki konfiguracyjne.
- [ ] ISSUE: `--dry-run` dla komend modyfikujących stan zasobów GitHub.
- [ ] ISSUE: Dodatkowe potwierdzenia i mechanizm bezpiecznika dla `delete/unsync`.
- [ ] ISSUE: Standaryzacja kodów wyjścia i formatu błędów.

## Epic B — Jakość i utrzymanie
- [ ] ISSUE: Testy jednostkowe dla `soc-lib.sh`.
- [ ] ISSUE: Testy jednostkowe dla `soc-lib-gh.sh`.
- [ ] ISSUE: Testy smoke dla ścieżki `init -> precheck -> sync`.
- [ ] ISSUE: Integracja lint/test w CI.

## Epic C — UX i operacyjność
- [ ] ISSUE: Rozbudowany `status` z metrykami kursu.
- [ ] ISSUE: Ujednolicony, czytelny output logów i tryb verbose.
- [ ] ISSUE: Raport eksportu CSV/JSON.
- [ ] ISSUE: Quick diagnostics (`doctor`) dla prowadzących.

## Epic D — Rozszerzalność i release
- [ ] ISSUE: Kontrakt interfejsu platformowego dla `soc-<platform>-*`.
- [ ] ISSUE: Szablon implementacji nowej platformy.
- [ ] ISSUE: SemVer + changelog + proces release.
