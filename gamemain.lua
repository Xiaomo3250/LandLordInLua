--斗地主

--全局变量
player1 = {}
player2 = {}
player3 = {}

--创建一副牌
function createDeck()
    local deck = {}
    local suits = { "C", "D", "H", "S" } -- H: Hearts, D: Diamonds, C: Clubs, S: Spades
    local ranks = { "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K" }
    for _, suit in ipairs(suits) do
        for _, rank in ipairs(ranks) do
            table.insert(deck, rank .. suit)
        end
    end
    -- Add the Jokers
    table.insert(deck, "BJ") --Black Joker
    table.insert(deck, "RJ") --Red Joker
    return deck
end

--洗牌
function shuffleDeck(deck)
    math.randomseed(os.time())
    for i = #deck, 2, -1 do
        local j = math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

--发牌
function dealCards(deck)
    local remaining = {}

    for i = 1, 17 do
        table.insert(player1, deck[i])
        table.insert(player2, deck[i + 17])
        table.insert(player3, deck[i + 34])
    end

    for i = 52, 54 do
        table.insert(remaining, deck[i])
    end

    return player1, player2, player3, remaining
end

--AI出牌
function AIPlayCards(player, lastPlayerCards)
    local cardsToPlay = {} -- AI玩家将要出的牌
    -- 这里我们简化一下，让AI玩家只会打出单张、对子和炸弹
    if #lastPlayerCards == 0 or #lastPlayerCards == 1 then
        -- 如果上一手牌为空或者单张，AI玩家可以打出单张
        table.insert(cardsToPlay, player[1]) -- 这里我们简化一下，直接打出第一张牌
    elseif #lastPlayerCards == 2 then
        -- 如果上一手牌是对子，AI玩家需要打出对子
        for i = 1, #player - 1 do
            if string.sub(player[i], 1, -2) == string.sub(player[i + 1], 1, -2) then
                table.insert(cardsToPlay, player[i])
                table.insert(cardsToPlay, player[i + 1])
                break
            end
        end
    elseif isBomb(lastPlayerCards) then
        -- 如果上一手牌是炸弹，AI玩家需要打出更大的炸弹或者火箭
        for i = 1, #player - 3 do
            if string.sub(player[i], 1, -2) == string.sub(player[i + 1], 1, -2)
                and string.sub(player[i], 1, -2) == string.sub(player[i + 2], 1, -2)
                and string.sub(player[i], 1, -2) == string.sub(player[i + 3], 1, -2) then
                table.insert(cardsToPlay, player[i])
                table.insert(cardsToPlay, player[i + 1])
                table.insert(cardsToPlay, player[i + 2])
                table.insert(cardsToPlay, player[i + 3])
                break
            end
        end
    end

    -- 如果没有找到合适的牌来打，那么就选择不出牌
    if #cardsToPlay == 0 then
        return cardsToPlay
    end

    -- 在这里判断牌型是否合法，如果不合法，AI玩家选择不出牌
    if isValidPlay(cardsToPlay, lastPlayerCards) then
        -- 从AI玩家手中移除这些牌
        for _, card in ipairs(cardsToPlay) do
            for i = 1, #player do
                if card == player[i] then
                    table.remove(player, i)
                    break
                end
            end
        end
        return cardsToPlay
    else
        return {}
    end
end

--AI叫分
function AICallScore()
    --默认叫2分
    return 2
end

--获取玩家叫分
function getPlayerPoints(player)
    if player == player1 then
        -- 如果是真人玩家，就像之前一样输入要叫的分数
        print("请输入你要叫的分数（0, 1, 2, 3）：")
        return tonumber(io.read())
    else
        -- 如果是AI玩家，就使用AI的叫分策略
        return AICallScore()
    end
end

-- 叫分
function callPoints()
    math.randomseed(os.time())
    local points = { 0, 1, 2, 3 }      -- 可选的分数：0 (不叫), 1, 2, 3
    local playerPoints = {}            -- 记录每个玩家的叫分
    local firstCaller = math.random(3) -- 随机选择第一个叫分的玩家

    for i = 0, 2 do
        local player = (firstCaller + i - 1) % 3 + 1
        -- 玩家输入分数
        print("玩家" .. player .. "请叫分(0, 1, 2, 3): ")
        local point = points[getPlayerPoints(player)]
        playerPoints[player] = point
        if point == 3 then -- 如果有玩家叫了3分，立即结束叫分
            return player, point, playerPoints
        end
    end

    local landlord = 0 -- 地主的编号
    local maxPoint = 0 -- 最高的分数

    -- 确定叫分最高的玩家为地主
    for player, point in pairs(playerPoints) do
        if point > maxPoint then
            landlord = player
            maxPoint = point
        end
    end

    if maxPoint == 0 then -- 如果所有玩家都选择不叫，本局流局
        return 0, 0, playerPoints
    else
        return landlord, maxPoint, playerPoints
    end
end

--炸弹判断
function isBomb(cards)
    if #cards == 4 then
        local rank = string.sub(cards[1], 1, -2)
        for _, card in ipairs(cards) do
            if string.sub(card, 1, -2) ~= rank then
                return false
            end
        end
        return true
    else
        return false
    end
end

--炸弹比较
function compareBomb(cards1, cards2)
    local rank1 = string.sub(cards1[1], 1, -2)
    local rank2 = string.sub(cards2[1], 1, -2)
    local rankMap = {
        ["3"] = 1,
        ["4"] = 2,
        ["5"] = 3,
        ["6"] = 4,
        ["7"] = 5,
        ["8"] = 6,
        ["9"] = 7,
        ["10"] = 8,
        ["J"] = 9,
        ["Q"] = 10,
        ["K"] = 11,
        ["A"] = 12,
        ["2"] = 13
    }
    return rankMap[rank1] > rankMap[rank2]
end

--火箭判断
function isRocket(cards)
    if #cards == 2 then
        if cards[1] == "BJ" and cards[2] == "RJ" then
            return true
        elseif cards[1] == "RJ" and cards[2] == "BJ" then
            return true
        else
            return false
        end
    else
        return false
    end
end

--单张比较
function compareSingle(cards1, cards2)
    local rank1 = string.sub(cards1[1], 1, -2)
    local rank2 = string.sub(cards2[1], 1, -2)
    local rankMap = {
        ["3"] = 1,
        ["4"] = 2,
        ["5"] = 3,
        ["6"] = 4,
        ["7"] = 5,
        ["8"] = 6,
        ["9"] = 7,
        ["10"] = 8,
        ["J"] = 9,
        ["Q"] = 10,
        ["K"] = 11,
        ["A"] = 12,
        ["2"] = 13
    }
    return rankMap[rank1] > rankMap[rank2]
end

--对子比较
function comparePair(cards1, cards2)
    local rank1 = string.sub(cards1[1], 1, -2)
    local rank2 = string.sub(cards2[1], 1, -2)
    local rankMap = {
        ["3"] = 1,
        ["4"] = 2,
        ["5"] = 3,
        ["6"] = 4,
        ["7"] = 5,
        ["8"] = 6,
        ["9"] = 7,
        ["10"] = 8,
        ["J"] = 9,
        ["Q"] = 10,
        ["K"] = 11,
        ["A"] = 12,
        ["2"] = 13
    }
    return rankMap[rank1] > rankMap[rank2]
end

--三张比较
function compareTriple(cards1, cards2)
    local rank1 = string.sub(cards1[1], 1, -2)
    local rank2 = string.sub(cards2[1], 1, -2)
    local rankMap = {
        ["3"] = 1,
        ["4"] = 2,
        ["5"] = 3,
        ["6"] = 4,
        ["7"] = 5,
        ["8"] = 6,
        ["9"] = 7,
        ["10"] = 8,
        ["J"] = 9,
        ["Q"] = 10,
        ["K"] = 11,
        ["A"] = 12,
        ["2"] = 13
    }
    return rankMap[rank1] > rankMap[rank2]
end

--三带一比较
function compareTripleWithSingle(cards1, cards2)
    local rank1 = string.sub(cards1[1], 1, -2)
    local rank2 = string.sub(cards2[1], 1, -2)
    local rankMap = {
        ["3"] = 1,
        ["4"] = 2,
        ["5"] = 3,
        ["6"] = 4,
        ["7"] = 5,
        ["8"] = 6,
        ["9"] = 7,
        ["10"] = 8,
        ["J"] = 9,
        ["Q"] = 10,
        ["K"] = 11,
        ["A"] = 12,
        ["2"] = 13
    }
    return rankMap[rank1] > rankMap[rank2]
end

--牌型合法判断
function isValidPlay(cardsToPlay, lastPlayerCards)
    -- 如果上一手牌是空，说明自己是第一个出牌的，因此牌型合法
    if #lastPlayerCards == 0 then
        return true
    end

    -- 如果手中有炸弹，可以打出任意非火箭的炸弹
    if isBomb(cardsToPlay) then
        return true
    end

    -- 如果上一手牌是火箭，只能用火箭压
    if isRocket(lastPlayerCards) then
        return false
    end

    -- 如果上一手牌是炸弹，只能用更大的炸弹压
    if isBomb(lastPlayerCards) then
        if isBomb(cardsToPlay) then
            return compareBomb(cardsToPlay, lastPlayerCards)
        else
            return false
        end
    end

    -- 如果上一手牌是单张，只能用更大的单张压
    if #lastPlayerCards == 1 then
        if #cardsToPlay == 1 then
            return compareSingle(cardsToPlay, lastPlayerCards)
        else
            return false
        end
    end

    -- 如果上一手牌是对子，只能用更大的对子压
    if #lastPlayerCards == 2 then
        if #cardsToPlay == 2 then
            return comparePair(cardsToPlay, lastPlayerCards)
        else
            return false
        end
    end

    -- 如果上一手牌是三张，只能用更大的三张压
    if #lastPlayerCards == 3 then
        if #cardsToPlay == 3 then
            return compareTriple(cardsToPlay, lastPlayerCards)
        else
            return false
        end
    end

    -- 如果上一手牌是三带一，只能用更大的三带一压
    if #lastPlayerCards == 4 then
        if #cardsToPlay == 4 then
            return compareTripleWithSingle(cardsToPlay, lastPlayerCards)
        else
            return false
        end
    end
end

--出牌
function playCards(player, lastPlayerCards)
    -- 询问玩家是否要出牌
    print("你现在有以下这些手牌: ")
    for i, card in ipairs(player) do
        print(i .. ": " .. card)
    end
    print("你想要出牌吗?(Y/N)")

    local response = io.read()
    if response == "yes" then
        -- 询问玩家要出哪几张牌
        print("你想要出哪些牌?")
        local cardNumbers = io.read()
        local cardsToPlay = {}
        for cardNumber in string.gmatch(cardNumbers, "%d+") do
            local cardIndex = tonumber(cardNumber)
            if cardIndex >= 1 and cardIndex <= #player then
                table.insert(cardsToPlay, player[cardIndex])
            end
        end

        -- 在这里判断牌型是否合法，如果不合法，提示玩家重新选择
        if isValidPlay(cardsToPlay, lastPlayerCards) then
            -- 从玩家手中移除这些牌
            for _, card in ipairs(cardsToPlay) do
                for i, playerCard in ipairs(player) do
                    if card == playerCard then
                        table.remove(player, i)
                        break
                    end
                end
            end
            return cardsToPlay
        else
            print("你所选择的牌型不合法,请重新选择")
            return playCards(player, lastPlayerCards)
        end
    else
        -- 如果玩家选择不出牌，返回空列表
        return {}
    end
end

-- AI
-- AI叫分
-- AI出牌

--游戏主程序
function main()
    --开始界面
    print("欢迎来到斗地主游戏")
    --创建一副新的牌
    local deck = createDeck()
    --洗牌
    shuffleDeck(deck)
    --分发牌
    local player1, player2, player3, remaining = dealCards(deck)
    --叫分
    local landlord, maxPoint, playerPoints = callPoints()
    if landlord == 0 then
        print("本局流局，请重新开始游戏")
        return false
    else
        print("地主是玩家" .. landlord .. "，叫了" .. maxPoint .. "分")
        for player, point in pairs(playerPoints) do
            print("玩家" .. player .. "叫了" .. point .. "分")
        end
        players = { player1, player2, player3 }
        local currentPlayer = landlord
        -- 将底牌加入地主的手牌
        for _, card in ipairs(remaining) do
            table.insert(players[landlord], card)
        end
        local lastPlayerCards = {}
        while true do
            --显示当前出牌的玩家
            print("玩家" .. currentPlayer .. "出牌")
            if players == player1 then
                cards = playCards(players[currentPlayer], lastPlayerCards)
            else
                cards = AIPlayCards(players[currentPlayer], lastPlayerCards)
            end
            if #cards == 0 then
                print("玩家" .. currentPlayer .. "选择不出牌")
            else
                print("玩家" .. currentPlayer .. "打出了以下牌:")
                for _, card in ipairs(cards) do
                    print(card)
                end
                lastPlayerCards = cards
            end
            -- 检查当前玩家手牌是否为空，如果是，则游戏结束
            if #players[currentPlayer] == 0 then
                print("玩家" .. currentPlayer .. "获胜")
                break
            end
            -- 逆时针轮换玩家
            currentPlayer = currentPlayer % 3 + 1
        end
    end
end
