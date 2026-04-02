# Анализ Telegram уведомления в Jenkins

## Текущий код
```groovy
script {
    def message = "❌ Проект $JOB_NAME подробнее: $BUILD_URL; Сборка $BUILD_ID Выполнена c ошибкой; длительность: ${currentBuild.duration} ms"
    notify.TGNotify("deb12:$message")
}
```

## Проблемы

### 1. Интерполяция переменных
- `$JOB_NAME`, `$BUILD_URL`, `$BUILD_ID` - работают, так как это переменные окружения Jenkins
- `${currentBuild.duration}` - правильный синтаксис для обращения к свойству объекта

### 2. Читаемость длительности
- `currentBuild.duration` возвращает время в **миллисекундах**
- Пример: `1234567 ms` (это ~20 минут)
- Для пользователя лучше отображать в минутах/секундах

## Исправленный код

### Вариант 1: С преобразованием времени
```groovy
script {
    def durationMs = currentBuild.duration
    def durationSec = durationMs / 1000
    def durationMin = durationSec / 60
    
    def durationText
    if (durationMin >= 1) {
        durationText = String.format("%.1f мин", durationMin)
    } else {
        durationText = String.format("%.0f сек", durationSec)
    }
    
    def message = "❌ Проект $JOB_NAME подробнее: $BUILD_URL; Сборка $BUILD_ID Выполнена c ошибкой; длительность: $durationText"
    notify.TGNotify("deb12:$message")
}
```

### Вариант 2: Простой (оставить миллисекунды)
```groovy
script {
    def message = "❌ Проект $JOB_NAME подробнее: $BUILD_URL; Сборка $BUILD_ID Выполнена c ошибкой; длительность: ${currentBuild.duration} ms"
    notify.TGNotify("deb12:$message")
}
```

### Вариант 3: Использование встроенного форматирования
```groovy
script {
    def durationFormatted = currentBuild.durationString // "20 min 15 sec"
    def message = "❌ Проект $JOB_NAME подробнее: $BUILD_URL; Сборка $BUILD_ID Выполнена c ошибкой; длительность: $durationFormatted"
    notify.TGNotify("deb12:$message")
}
```

**Примечание**: `currentBuild.durationString` может быть доступен не во всех версиях Jenkins.

## Рекомендация

Использовать **Вариант 1** с преобразованием времени, так как он:
1. Делает сообщение более читаемым
2. Работает во всех версиях Jenkins
3. Показывает время в понятном формате

## Дополнительные улучшения

### Добавить статус сборки
```groovy
def status = currentBuild.result ?: "UNKNOWN"
def message = "❌ Проект $JOB_NAME (Статус: $status) подробнее: $BUILD_URL; Сборка $BUILD_ID; длительность: $durationText"
```

### Ссылка на Allure отчёт (если есть)
```groovy
def allureUrl = "${BUILD_URL}allure/"
def message = "❌ Проект $JOB_NAME подробнее: $BUILD_URL (Allure: $allureUrl); Сборка $BUILD_ID; длительность: $durationText"
```

## Полный пример
```groovy
script {
    // Форматирование времени
    def durationMs = currentBuild.duration
    def durationSec = durationMs / 1000
    def durationMin = durationSec / 60
    
    def durationText
    if (durationMin >= 1) {
        def remainingSec = durationSec % 60
        durationText = "${Math.floor(durationMin)} мин ${Math.round(remainingSec)} сек"
    } else {
        durationText = "${Math.round(durationSec)} сек"
    }
    
    // Статус сборки
    def status = currentBuild.result ?: "UNKNOWN"
    
    // Сообщение
    def message = "❌ Проект: $JOB_NAME\n" +
                  "Статус: $status\n" +
                  "Сборка: $BUILD_ID\n" +
                  "Длительность: $durationText\n" +
                  "Подробнее: $BUILD_URL"
    
    // Отправка
    notify.TGNotify("deb12:$message")
}
```

## Тестирование
После внесения изменений:
1. Запустите сборку, которая завершится ошибкой
2. Проверьте Telegram уведомление
3. Убедитесь, что время отображается в читаемом формате