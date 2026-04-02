# Округление времени в Jenkins Groovy

## Текущий код пользователя
```groovy
def durationMin = currentBuild.duration / 60000
def durayionMinRound = Math.round(durationMin)
echo "Длительность сборки: ${durationMin} min"

script {
    def message = "❌ Проект $JOB_NAME подробнее: $BUILD_URL; Сборка $BUILD_ID Выполнена c ошибкой; длительность: ${currentBuild.duration} ms = ${durationMin} min"
    notify.TGNotify("deb12:$message")
}
```

## Вопросы и ответы

### 1. Округление до 2 значений после запятой

**Вариант A: Использовать String.format**
```groovy
def durationMin = currentBuild.duration / 60000
def durationMinRounded = String.format("%.2f", durationMin)
// Пример: 12.34567 -> "12.35"
```

**Вариант B: Использовать Math.round с умножением**
```groovy
def durationMin = currentBuild.duration / 60000
def durationMinRounded = Math.round(durationMin * 100) / 100.0
// Пример: 12.34567 * 100 = 1234.567 -> round = 1235 -> /100.0 = 12.35
```

**Вариант C: Использовать DecimalFormat**
```groovy
import java.text.DecimalFormat
def durationMin = currentBuild.duration / 60000
def df = new DecimalFormat("#.##")
def durationMinRounded = df.format(durationMin)
// Пример: 12.34567 -> "12.35"
```

### 2. Что означает функция `floor`?

- **`Math.floor(value)`** - округление вниз до ближайшего целого числа
- **`Math.ceil(value)`** - округление вверх до ближайшего целого числа  
- **`Math.round(value)`** - математическое округление (0.5 и выше - вверх, меньше 0.5 - вниз)

Примеры:
```groovy
Math.floor(12.7)  // = 12.0
Math.floor(12.2)  // = 12.0
Math.ceil(12.2)   // = 13.0
Math.ceil(12.7)   // = 13.0
Math.round(12.4)  // = 12
Math.round(12.5)  // = 13
```

## Улучшенный код с округлением до 2 знаков

### Вариант 1: Простой (String.format)
```groovy
def durationMs = currentBuild.duration
def durationMin = durationMs / 60000.0
def durationMinRounded = String.format("%.2f", durationMin)

def message = "❌ Проект $JOB_NAME подробнее: $BUILD_URL; Сборка $BUILD_ID Выполнена c ошибкой; длительность: ${durationMinRounded} мин"
notify.TGNotify("deb12:$message")
```

### Вариант 2: С разбивкой на минуты и секунды
```groovy
def durationMs = currentBuild.duration
def durationSec = durationMs / 1000.0
def durationMin = durationSec / 60.0

// Округление до 2 знаков
def durationMinRounded = Math.round(durationMin * 100) / 100.0

// Альтернативно: минуты и секунды отдельно
def minutes = Math.floor(durationSec / 60)
def seconds = Math.round(durationSec % 60)

def message = "❌ Проект $JOB_NAME подробнее: $BUILD_URL; Сборка $BUILD_ID Выполнена c ошибкой; длительность: ${minutes} мин ${seconds} сек (${durationMinRounded} мин)"
notify.TGNotify("deb12:$message")
```

### Вариант 3: Универсальный с выбором формата
```groovy
def durationMs = currentBuild.duration
def durationSec = durationMs / 1000.0

def durationText
if (durationSec < 60) {
    durationText = String.format("%.1f сек", durationSec)
} else if (durationSec < 3600) {
    def minutes = durationSec / 60.0
    durationText = String.format("%.2f мин", minutes)
} else {
    def hours = durationSec / 3600.0
    durationText = String.format("%.2f ч", hours)
}

def message = "❌ Проект $JOB_NAME подробнее: $BUILD_URL; Сборка $BUILD_ID Выполнена c ошибкой; длительность: $durationText"
notify.TGNotify("deb12:$message")
```

## Рекомендация

Использовать **Вариант 3**, так как он:
1. Автоматически выбирает подходящие единицы измерения (секунды, минуты, часы)
2. Округляет до разумного количества знаков
3. Делает сообщение более читаемым

## Полный пример для вставки в Jenkinsfile

```groovy
script {
    // Рассчёт и форматирование длительности
    def durationMs = currentBuild.duration
    def durationSec = durationMs / 1000.0
    
    def durationText
    if (durationSec < 60) {
        // Меньше минуты: показываем секунды с 1 знаком после запятой
        durationText = String.format("%.1f сек", durationSec)
    } else if (durationSec < 3600) {
        // Меньше часа: показываем минуты с 2 знаками после запятой
        def minutes = durationSec / 60.0
        durationText = String.format("%.2f мин", minutes)
    } else {
        // Больше часа: показываем часы с 2 знаками после запятой
        def hours = durationSec / 3600.0
        durationText = String.format("%.2f ч", hours)
    }
    
    // Формирование сообщения
    def message = "❌ Проект: $JOB_NAME\n" +
                  "Сборка: $BUILD_ID\n" +
                  "Статус: ${currentBuild.result ?: 'UNKNOWN'}\n" +
                  "Длительность: $durationText\n" +
                  "Подробнее: $BUILD_URL"
    
    // Отправка уведомления
    notify.TGNotify("deb12:$message")
}
```

## Тестирование
После внесения изменений проверьте:
1. Запустите сборку, которая завершится ошибкой
2. Проверьте Telegram уведомление
3. Убедитесь, что время отображается в правильном формате с округлением