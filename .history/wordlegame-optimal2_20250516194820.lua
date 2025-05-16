#!/usr/bin/env luajit

-- ----------------------------------------------------------------------------
-- Скрипт: find_words.lua
-- Описание: Из словаря извлекает комбинации из NUM_WORDS слов по N букв,
-- у которых количество уникальных букв, повторяющихся в комбинации, не превышает ALLOWED_DUPLICATES.
-- Длина слова N определяется автоматически по первому слову в словаре, если не указана.
-- Параметры:
--   arg[1] — файл словаря (по одному слову в строке)
--   arg[2] (опционально) — длина слов N (если не указана, берется из первого слова)
--   arg[3] (опционально) — количество слов в комбинации NUM_WORDS (по умолчанию 3)
--   arg[4] (опционально) — количество комбинаций для вывода MAX_OUTPUT (по умолчанию 15)
--   arg[5] (опционально) — допустимое количество уникальных повторяющихся букв ALLOWED_DUPLICATES (по умолчанию 0)
-- При каждом запуске случайно выбирает точку старта в словаре.
-- ----------------------------------------------------------------------------

local function is_unique(word)
    local seen = {}
    for i = 1, #word do
        local ch = word:sub(i, i)
        if seen[ch] then return false end
        seen[ch] = true
    end
    return true
end

local function count_duplicates(combination, frequent_letters, check_frequent)
    local letter_count = {}
    for _, word in ipairs(combination) do
        for i = 1, #word do
            local ch = word:sub(i, i)
            letter_count[ch] = (letter_count[ch] or 0) + 1
        end
    end
    local duplicates = 0
    if check_frequent then
        for ch, _ in pairs(frequent_letters) do
            if letter_count[ch] and letter_count[ch] > 1 then
                duplicates = duplicates + 1
            end
        end
    else
        for ch, count in pairs(letter_count) do
            if count > 1 then
                duplicates = duplicates + 1
            end
        end
    end
    return duplicates
end

local function can_add_word(word, combination, allowed_duplicates, frequent_letters)
    local temp_combination = {word}
    for _, w in ipairs(combination) do
        table.insert(temp_combination, w)
    end
    local freq_duplicates = count_duplicates(temp_combination, frequent_letters, true)
    if freq_duplicates > allowed_duplicates then return false end
    local total_duplicates = count_duplicates(temp_combination, frequent_letters, false)
    return total_duplicates <= allowed_duplicates
end

local function generate_combinations(words, current_combination, start_index, num_words, allowed_duplicates, frequent_letters, max_output, found)
    if #current_combination == num_words then
        print(table.concat(current_combination, " "))
        found[1] = found[1] + 1
        if found[1] >= max_output then os.exit(0) end
        return
    end
    for i = start_index, #words do
        local word = words[i]
        if can_add_word(word, current_combination, allowed_duplicates, frequent_letters) then
            table.insert(current_combination, word)
            generate_combinations(words, current_combination, i + 1, num_words, allowed_duplicates, frequent_letters, max_output, found)
            table.remove(current_combination)
        end
    end
end

if #arg < 1 then
    io.stderr:write("Ошибка: не указан файл словаря.\n")
    io.stderr:write("Использование: ./find_words.lua словарь.txt [N] [NUM_WORDS] [MAX_OUTPUT] [ALLOWED_DUPLICATES]\n")
    os.exit(1)
end

local dict_file = arg[1]
local targetLen
if arg[2] and tonumber(arg[2]) then
    targetLen = tonumber(arg[2])
else
    local file = io.open(dict_file, "r")
    if not file then
        io.stderr:write("Ошибка: не удается открыть файл словаря.\n")
        os.exit(1)
    end
    local first_line = file:read("*l")
    if not first_line then
        io.stderr:write("Ошибка: словарь пуст.\n")
        os.exit(1)
    end
    targetLen = #first_line
    file:close()
end

local NUM_WORDS = arg[3] and tonumber(arg[3]) or 3
local MAX_OUTPUT = arg[4] and tonumber(arg[4]) or 15
local ALLOWED_DUPLICATES = arg[5] and tonumber(arg[5]) or 0

local frequent_letters = {["о"]=true, ["е"]=true, ["а"]=true, ["и"]=true, ["н"]=true}

local words = {}
local file = io.open(dict_file, "r")
if not file then
    io.stderr:write("Ошибка: не удается открыть файл словаря.\n")
    os.exit(1)
end
for line in file:lines() do
    local word = string.lower(line)
    if #word == targetLen and is_unique(word) then
        table.insert(words, word)
    end
end
file:close()

if #words < NUM_WORDS then
    io.stderr:write("Недостаточно слов для поиска комбинаций.\n")
    os.exit(1)
end

math.randomseed(os.time())
local start = math.random(1, #words)

local found = {0}
for offset_i = 0, #words - 1 do
    local i = (start + offset_i - 1) % #words + 1
    local current_combination = {words[i]}
    generate_combinations(words, current_combination, i + 1, NUM_WORDS, ALLOWED_DUPLICATES, frequent_letters, MAX_OUTPUT, found)
    if found[1] >= MAX_OUTPUT then break end
end

if found[1] == 0 then
    io.stderr:write("Комбинаций не найдено.\n")
    os.exit(1)
end