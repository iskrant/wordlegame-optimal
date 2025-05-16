#!/usr/bin/env luajit
--[[
Скрипт: find_words.lua
Описание: Из словаря извлекает комбинации из NUM_WORDS слов по N букв,
у которых количество уникальных букв, повторяющихся в комбинации, не превышает ALLOWED_DUPLICATES.
Сначала проверяются 5 самых частых букв русского языка: "о", "е", "а", "и", "н".
Параметры:
  arg[1] — файл словаря (по одному слову в строке)
  arg[2] (опционально) — длина слов N (по умолчанию определяется по первому слову)
  arg[3] (опционально) — количество слов в комбинации NUM_WORDS (по умолчанию 3)
  arg[4] (опционально) — количество комбинаций для вывода MAX_OUTPUT (по умолчанию 15)
  arg[5] (опционально) — допустимое количество уникальных повторяющихся букв ALLOWED_DUPLICATES (по умолчанию 0)
При каждом запуске случайно выбирает точку старта в словаре.
--]]

-- Проверка уникальности букв в слове
local function is_unique(word)
    local seen = {}
    for uchar in word:gmatch('.') do
        if seen[uchar] then return false end
        seen[uchar] = true
    end
    return true
end

-- Подсчет уникальных букв, повторяющихся в комбинации
local function count_duplicates(combination, frequent_letters, check_frequent)
    local letter_count = {}
    for _, w in ipairs(combination) do
        for uchar in w:gmatch('.') do
            letter_count[uchar] = (letter_count[uchar] or 0) + 1
        end
    end
    local duplicates = 0
    if check_frequent then
        for ch in pairs(frequent_letters) do
            if letter_count[ch] and letter_count[ch] > 1 then
                duplicates = duplicates + 1
            end
        end
    else
        for ch, cnt in pairs(letter_count) do
            if cnt > 1 then duplicates = duplicates + 1 end
        end
    end
    return duplicates
end

-- Проверка возможности добавить слово к комбинации
local function can_add_word(word, combination, allowed_duplicates, frequent_letters)
    local temp = {word}
    for _, v in ipairs(combination) do table.insert(temp, v) end
    if count_duplicates(temp, frequent_letters, true) > allowed_duplicates then
        return false
    end
    if count_duplicates(temp, frequent_letters, false) > allowed_duplicates then
        return false
    end
    return true
end

-- Рекурсивная генерация комбинаций
local function generate_combinations(current, start_idx, words, num_words, max_output, allowed_duplicates, frequent_letters, found)
    if #current == num_words then
        print(table.concat(current, ' '))
        found.count = found.count + 1
        return found.count >= max_output
    end
    for i = start_idx, #words do
        local w = words[i]
        if can_add_word(w, current, allowed_duplicates, frequent_letters) then
            table.insert(current, w)
            if generate_combinations(current, i + 1, words, num_words, max_output, allowed_duplicates, frequent_letters, found) then
                return true
            end
            table.remove(current)
        end
    end
    return false
end

-- Основная часть
local dict_file = arg[1]
if not dict_file then
    io.stderr:write("Ошибка: не указан файл словаря.\n")
    io.stderr:write("Использование: ./find_words.lua словарь.txt [N] [NUM_WORDS] [MAX_OUTPUT] [ALLOWED_DUPLICATES]\n")
    os.exit(1)
end

local targetLen = tonumber(arg[2])
local NUM_WORDS = tonumber(arg[3]) or 3
local MAX_OUTPUT = tonumber(arg[4]) or 15
local ALLOWED_DUPLICATES = tonumber(arg[5]) or 0

-- Частые буквы русского языка
local frequent_letters = { ["о"] = true, ["е"] = true, ["а"] = true, ["и"] = true, ["н"] = true }

-- Чтение словаря
local words = {}
for line in io.lines(dict_file) do
    local w = line:lower():gsub("%s+", "")
    if #words == 0 and not targetLen then targetLen = #w end
    if #w == targetLen and is_unique(w) then
        table.insert(words, w)
    end
end

if #words < NUM_WORDS then
    io.stderr:write("Недостаточно слов для поиска комбинаций.\n")
    os.exit(1)
end

-- Инициализация генератора случайных чисел
math.randomseed(os.time())

local count = #words
local start = math.random(1, count)
local found = { count = 0 }

-- Основной цикл с произвольной точкой старта
for offset = 0, count - 1 do
    local idx = ((start + offset - 1) % count) + 1
    local current = { words[idx] }
    if generate_combinations(current, idx + 1, words, NUM_WORDS, MAX_OUTPUT, ALLOWED_DUPLICATES, frequent_letters, found) then
        break
    end
    if found.count >= MAX_OUTPUT then break end
end

if found.count == 0 then
    io.stderr:write("Комбинаций не найдено.\n")
    os.exit(1)
end
