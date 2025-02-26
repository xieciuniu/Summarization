# Summarizator - Aplikacja do sumaryzacji wykładów

## Opis

Summarizator to aplikacja iOS, która umożliwia nagrywanie wykładów, ich transkrypcję i automatyczne tworzenie podsumowań z wykorzystaniem modeli językowych (LLM). Aplikacja pozwala na:

- Nagrywanie dźwięku wykładów
- Automatyczną transkrypcję mowy na tekst przy użyciu iOS Speech framework
- Generowanie strukturyzowanych notatek i podsumowań wykładów przy użyciu wybranego modelu LLM
- Przechowywanie i zarządzanie nagraniami, transkrypcjami i podsumowaniami
- Łatwą wymianę notatek z wykładów

## Architektura

Aplikacja wykorzystuje architekturę MVVM (Model-View-ViewModel) dla czystego podziału odpowiedzialności i łatwiejszego testowania. Główne komponenty aplikacji to:

- **Model**: Struktury danych reprezentujące nagrania, transkrypcje i podsumowania
- **View**: Interfejs użytkownika zbudowany przy użyciu SwiftUI
- **ViewModel**: Logika biznesowa i komunikacja z usługami
- **Services**: Komponenty odpowiedzialne za nagrywanie audio, transkrypcję i komunikację z API LLM

## Funkcje

- Nagrywanie wykładów z funkcjami pauzy i wznowienia
- Wbudowana transkrypcja mowy na tekst (offline)
- Integracja z różnymi dostawcami LLM (OpenAI, Anthropic Claude, Google Gemini, Mistral AI, Ollama)
- Bezpieczne przechowywanie kluczy API w iOS Keychain
- Możliwość dostosowania instrukcji dla modelu językowego
- Udostępnianie notatek przez standardowe usługi iOS

## Wymagania

- iOS 15.0 lub nowszy
- Xcode 13.0 lub nowszy
- Konto deweloperskie Apple (do uruchomienia na prawdziwym urządzeniu)
- Klucze API od wybranego dostawcy LLM (opcjonalne, wbudowana obsługa Ollama dla modeli lokalnych)

## Instalacja

1. Sklonuj repozytorium
2. Otwórz projekt w Xcode
3. Skonfiguruj podpis deweloperski
4. Zbuduj i uruchom aplikację

## Wykorzystane technologie

- SwiftUI dla interfejsu użytkownika
- Combine framework dla programowania reaktywnego
- AVFoundation do nagrywania dźwięku
- Speech framework do rozpoznawania mowy
- UserDefaults i FileManager do przechowywania danych
- Keychain dla bezpiecznego przechowywania kluczy API

## Licencja

Projekt jest dostępny na licencji MIT. Szczegóły znajdziesz w pliku LICENSE.
