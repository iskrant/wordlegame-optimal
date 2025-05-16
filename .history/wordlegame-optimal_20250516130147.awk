#!/usr/bin/awk -f

# ----------------------------------------------------------------------------
# Скрипт: find_words.awk
# Описание: Из словаря извлекает комбинации из NUM_WORDS слов по N букв,
# у которых количество уникальных букв, повторяющихся в комбинации, не превышает ALLOWED_DUPLICATES.
# Длина слова N определяется автоматически по первому слову в словаре, если не указана.
# Параметры:
#   ARGV[1] — файл словаря (по одному слову в строке)
#   ARGV[2] (опционально) — длина слов N (если не указана, берется из первого слова)
#   ARGV[3] (опционально) — количество слов в комбинации NUM_WORDS (по умолчанию 3)
#   ARGV[4] (опционально) — количество комбинаций для вывода MAX_OUTPUT (по умолчанию 15)
#   ARGV[5] (опционально) — допустимое количество уникальных повторяющихся букв ALLOWED_DUPLICATES (по умолчанию 0)
# При каждом запуске случайно выбирает точку старта в словаре.
# ----------------------------------------------------------------------------

# Проверяет, что все буквы в слове уникальны
function is_unique(word,    i, seen, ch) {
    delete seen
    for (i = 1; i <= length(word); i++) {
        ch = substr(word, i, 1)
        if (ch in seen) return 0
        seen[ch] = 1
    }
    return 1
}

# Считает количество уникальных букв, которые повторяются в комбинации
function count_duplicates(combination, frequent_letters, check_frequent,    letter_count, i, j, ch, duplicates) {
    delete letter_count
    for (i in combination) {
        for (j = 1; j <= length(combination[i]); j++) {
            ch = substr(combination[i], j, 1)
            if (ch in letter_count) {
                letter_count[ch]++
            } else {
                letter_count[ch] = 1
            }
        }
    }
    duplicates = 0
    if (check_frequent) {
        for (ch in frequent_letters) {
            if (letter_count[ch] > 1) {
                duplicates++
            }
        }
    } else {
        for (ch in letter_count) {
            if (letter_count[ch] > 1) {
                duplicates++
            }
        }
    }
    return duplicates
}

# Проверяет, можно ли добавить слово к комбинации
function can_add_word(word, combination, allowed_duplicates, frequent_letters,    temp_combination, freq_duplicates, total_duplicates) {
    temp_combination[1] = word
    for (i in combination) {
        temp_combination[length(temp_combination) + 1] = combination[i]
    }
    # Сначала проверяем частые буквы
    freq_duplicates = count_duplicates(temp_combination, frequent_letters, 1)
    if (freq_duplicates > allowed_duplicates) return 0
    # Затем проверяем все буквы
    total_duplicates = count_duplicates(temp_combination, frequent_letters, 0)
    return total_duplicates <= allowed_duplicates
}

# Рекурсивная функция для генерации комбинаций
function generate_combinations(current_combination, start_index, allowed_duplicates, frequent_letters,    i, word) {
    if (length(current_combination) == NUM_WORDS) {
        for (i = 1; i <= NUM_WORDS; i++) {
            printf "%s ", current_combination[i]
        }
        print ""
        found++
        if (found >= MAX_OUTPUT) exit
        return
    }
    for (i = start_index; i <= count; i++) {
        word = words[i]
        if (can_add_word(word, current_combination, allowed_duplicates, frequent_letters)) {
            current_combination[length(current_combination) + 1] = word
            generate_combinations(current_combination, i + 1, allowed_duplicates, frequent_letters)
            delete current_combination[length(current_combination)]
        }
    }
}

BEGIN {
    if (ARGC < 2) {
        print "Ошибка: не указан файл словаря." > "/dev/stderr"
        print "Использование: ./find_words.awk словарь.txt [N] [NUM_WORDS] [MAX_OUTPUT] [ALLOWED_DUPLICATES]" > "/dev/stderr"
        exit 1
    }

    dict_file = ARGV[1]
    delete ARGV[1]

    # Определение длины слова N
    if (ARGC >= 3 && ARGV[2] ~ /^[0-9]+$/) {
        targetLen = ARGV[2] + 0
        delete ARGV[2]
    } else {
        # Читаем первое слово для определения длины
        if ((getline first_line < dict_file) > 0) {
            first_word = tolower(first_line)
            targetLen = length(first_word)
        } else {
            print "Ошибка: словарь пуст." > "/dev/stderr"
            exit 1
        }
        close(dict_file)
    }

    if (ARGC >= 3 && ARGV[2] ~ /^[0-9]+$/) {
        NUM_WORDS = ARGV[2] + 0
    } else {
        NUM_WORDS = 3
    }
    if (ARGC >= 4 && ARGV[3] ~ /^[0-9]+$/) {
        MAX_OUTPUT = ARGV[3] + 0
    } else {
        MAX_OUTPUT = 15
    }
    if (ARGC >= 5 && ARGV[4] ~ /^[0-9]+$/) {
        ALLOWED_DUPLICATES = ARGV[4] + 0
    } else {
        ALLOWED_DUPLICATES = 0
    }

    # Определяем 5 самых частых букв русского языка
    frequent_letters["о"]
    frequent_letters["е"]
    frequent_letters["а"]
    frequent_letters["и"]
    frequent_letters["н"]

    count = 0
    while ((getline line < dict_file) > 0) {
        word = tolower(line)
        if (length(word) == targetLen && is_unique(word)) {
            words[++count] = word
        }
    }
    close(dict_file)

    if (count < NUM_WORDS) {
        print "Недостаточно слов для поиска комбинаций." > "/dev/stderr"
        exit 1
    }

    srand()
    start = int(rand() * count) + 1

    found = 0
    for (offset_i = 0; offset_i < count; offset_i++) {
        i = ((start + offset_i - 1) % count) + 1
        current_combination[1] = words[i]
        generate_combinations(current_combination, i + 1, ALLOWED_DUPLICATES, frequent_letters)
        delete current_combination
        if (found >= MAX_OUTPUT) break
    }

    if (found == 0) {
        print "Комбинаций не найдено." > "/dev/stderr"
        exit 1
    }
}