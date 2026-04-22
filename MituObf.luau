-- ================================================================
--   LUAU OBFUSCATOR — Complete Single-File Implementation
--   Sections: Config · RNG · Token · Lexer · Parser · Walker
--             NameGen · Encryptor · StringTable · Passes 1-7
--             CodeGenerator · Pipeline · Entry Point
-- ================================================================

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SECTION 1 · CONFIG                                         ║
-- ╚══════════════════════════════════════════════════════════════╝
local Config = {
    seed           = os.time(),
    namingStyle    = "HOMOGLYPH",  -- "HOMOGLYPH" | "HEX" | "UNDERSCORE"
    encryptMode    = "XOR",        -- "XOR" | "ADD"
    junkDensity    = "MEDIUM",     -- "LOW" | "MEDIUM" | "HIGH"
    tamperResponse = "LOOP",       -- "LOOP" | "ERROR" | "CORRUPT"
    flattenFlow    = true,
    encodeConsts   = true,
    injectJunk     = true,
    antiTamper     = true,
    integrityLayer = true,
}

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SECTION 2 · SEEDED RNG                                     ║
-- ╚══════════════════════════════════════════════════════════════╝
local RNG = (function()
    local s = Config.seed
    local function next()
        s = (s * 1664525 + 1013904223) % 4294967296
        return s
    end
    local function int(lo, hi)
        return lo + (next() % (hi - lo + 1))
    end
    local function pick(t)
        return t[int(1, #t)]
    end
    local function chance(pct)   -- pct: 0–100
        return int(1, 100) <= pct
    end
    return { next = next, int = int, pick = pick, chance = chance }
end)()

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SECTION 3 · TOKEN TYPES                                    ║
-- ╚══════════════════════════════════════════════════════════════╝
local TK = {
    NAME = 1, NUMBER = 2, STRING = 3, OP = 4, KEYWORD = 5, EOF = 6,
    keywords = {
        ["and"]=true,  ["break"]=true,    ["do"]=true,       ["else"]=true,
        ["elseif"]=true,["end"]=true,     ["false"]=true,    ["for"]=true,
        ["function"]=true,["if"]=true,    ["in"]=true,       ["local"]=true,
        ["nil"]=true,  ["not"]=true,      ["or"]=true,       ["repeat"]=true,
        ["return"]=true,["then"]=true,    ["true"]=true,     ["until"]=true,
        ["while"]=true,["goto"]=true,     ["continue"]=true,
    }
}

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SECTION 4 · LEXER                                          ║
-- ╚══════════════════════════════════════════════════════════════╝
local Lexer = (function()
    local function tokenize(src)
        local tokens, i, line, len = {}, 1, 1, #src

        local function ch(off) return src:sub(i+(off or 0), i+(off or 0)) end
        local function adv(n)  i = i + (n or 1) end
        local function add(k, v) tokens[#tokens+1] = {kind=k, value=v, line=line} end

        local function readLongString()
            -- called when ch() == '['; checks for [[...]] or [=[...]=] etc.
            local level = 0
            local j = i + 1
            while src:sub(j, j) == '=' do level = level + 1; j = j + 1 end
            if src:sub(j, j) ~= '[' then return nil end
            i = j + 1  -- skip past opening [[
            local close = ']' .. string.rep('=', level) .. ']'
            local e = src:find(close, i, true)
            if not e then error("Unclosed long string at line " .. line) end
            local content = src:sub(i, e - 1)
            if content:sub(1, 1) == '\n' then content = content:sub(2) end
            for _ in content:gmatch('\n') do line = line + 1 end
            i = e + #close
            return content
        end

        while i <= len do
            local c = ch()

            -- Whitespace
            if c == ' ' or c == '\t' or c == '\r' then
                adv()
            elseif c == '\n' then
                line = line + 1; adv()

            -- Comments
            elseif c == '-' and ch(1) == '-' then
                adv(2)
                if ch() == '[' then
                    local saved = i
                    local content = readLongString()
                    if not content then
                        i = saved
                        while i <= len and ch() ~= '\n' do adv() end
                    end
                else
                    while i <= len and ch() ~= '\n' do adv() end
                end

            -- Long strings
            elseif c == '[' and (ch(1) == '[' or ch(1) == '=') then
                local saved = i
                local content = readLongString()
                if content then
                    add(TK.STRING, content)
                else
                    i = saved; add(TK.OP, '['); adv()
                end

            -- Short strings
            elseif c == '"' or c == "'" then
                local q = c; adv()
                local parts = {}
                while i <= len and ch() ~= q do
                    local x = ch()
                    if x == '\\' then
                        adv()
                        local e = ch(); adv()
                        if     e == 'n'  then parts[#parts+1] = '\n'
                        elseif e == 't'  then parts[#parts+1] = '\t'
                        elseif e == 'r'  then parts[#parts+1] = '\r'
                        elseif e == '\\'  then parts[#parts+1] = '\\'
                        elseif e == '"'  then parts[#parts+1] = '"'
                        elseif e == "'"  then parts[#parts+1] = "'"
                        elseif e == 'a'  then parts[#parts+1] = '\a'
                        elseif e == 'b'  then parts[#parts+1] = '\b'
                        elseif e == 'f'  then parts[#parts+1] = '\f'
                        elseif e == 'v'  then parts[#parts+1] = '\v'
                        elseif e == '0'  then parts[#parts+1] = '\0'
                        elseif e:match('%d') then
                            local num = e
                            if ch():match('%d') then num = num .. ch(); adv() end
                            if ch():match('%d') then num = num .. ch(); adv() end
                            parts[#parts+1] = string.char(tonumber(num))
                        elseif e == 'x' then
                            local h = ch() .. src:sub(i+1, i+1); adv(2)
                            parts[#parts+1] = string.char(tonumber(h, 16))
                        elseif e == '\n' then
                            line = line + 1; parts[#parts+1] = '\n'
                        else
                            parts[#parts+1] = e
                        end
                    elseif x == '\n' then
                        line = line + 1; parts[#parts+1] = x; adv()
                    else
                        parts[#parts+1] = x; adv()
                    end
                end
                adv()  -- closing quote
                add(TK.STRING, table.concat(parts))

            -- Numbers
            elseif c:match('%d') or (c == '.' and ch(1):match('%d')) then
                local s = i
                if c == '0' and ch(1):lower() == 'x' then
                    adv(2)
                    while ch():match('[%x_]') do adv() end
                else
                    while ch():match('[%d_]') do adv() end
                    if ch() == '.' and ch(1):match('%d') then
                        adv()
                        while ch():match('[%d_]') do adv() end
                    end
                    if ch():lower() == 'e' then
                        adv()
                        if ch():match('[%+%-]') then adv() end
                        while ch():match('%d') do adv() end
                    end
                end
                add(TK.NUMBER, src:sub(s, i-1):gsub('_', ''))

            -- Identifiers / keywords
            elseif c:match('[%a_]') then
                local s = i
                while ch():match('[%w_]') do adv() end
                local word = src:sub(s, i-1)
                if TK.keywords[word] then add(TK.KEYWORD, word)
                else add(TK.NAME, word) end

            -- Operators / punctuation
            else
                local s3 = src:sub(i, i+2)
                local s2 = src:sub(i, i+1)
                if     s3 == '...' then add(TK.OP, '...'); adv(3)
                elseif s2 == '..'  then add(TK.OP, '..'); adv(2)
                elseif s2 == '=='  then add(TK.OP, '=='); adv(2)
                elseif s2 == '~='  then add(TK.OP, '~='); adv(2)
                elseif s2 == '<='  then add(TK.OP, '<='); adv(2)
                elseif s2 == '>='  then add(TK.OP, '>='); adv(2)
                elseif s2 == '::'  then add(TK.OP, '::'); adv(2)
                elseif s2 == '<<'  then add(TK.OP, '<<'); adv(2)
                elseif s2 == '>>'  then add(TK.OP, '>>'); adv(2)
                elseif s2 == '//'  then add(TK.OP, '//'); adv(2)
                else add(TK.OP, c); adv() end
            end
        end

        add(TK.EOF, nil)
        return tokens
    end

    return { tokenize = tokenize }
end)()

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SECTION 5 · PARSER                                         ║
-- ╚══════════════════════════════════════════════════════════════╝
local Parser = (function()
    local tokens, pos

    local function cur()       return tokens[pos] or tokens[#tokens] end
    local function peek(off)   return tokens[pos + (off or 0)] or tokens[#tokens] end
    local function adv()       local t = tokens[pos]; pos = pos + 1; return t end

    local function is(kind, val)
        local t = cur()
        return val ~= nil and (t.kind == kind and t.value == val) or t.kind == kind
    end
    local function isv(val)    return cur().value == val end

    local function expect(kind, val)
        if not is(kind, val) then
            local t = cur()
            error(("Parser: expected %s(%s) got %s(%s) line %d"):format(
                kind, tostring(val), t.kind, tostring(t.value), t.line), 2)
        end
        return adv()
    end
    local function match(kind, val)
        if is(kind, val) then return adv() end
        return nil
    end

    -- Forward declarations
    local parseBlock, parseExpr, parseStat, parsePrimaryExpr, parseSimpleExpr

    -- ── Shared helpers ───────────────────────────────────────
    local function parseFuncBody()
        expect(TK.OP, '(')
        local params, hasVarArg = {}, false
        if not is(TK.OP, ')') then
            if is(TK.OP, '...') then
                hasVarArg = true; adv()
            else
                params[#params+1] = expect(TK.NAME).value
                while match(TK.OP, ',') do
                    if is(TK.OP, '...') then hasVarArg = true; adv(); break end
                    params[#params+1] = expect(TK.NAME).value
                end
            end
        end
        expect(TK.OP, ')')
        local block = parseBlock()
        expect(TK.KEYWORD, 'end')
        return {kind="FuncExpr", params=params, hasVarArg=hasVarArg, block=block}
    end

    local function parseExprList()
        local list = {parseExpr()}
        while match(TK.OP, ',') do list[#list+1] = parseExpr() end
        return list
    end

    local function parseCallArgs()
        if is(TK.OP, '(') then
            adv()
            if is(TK.OP, ')') then adv(); return {} end
            local args = parseExprList()
            expect(TK.OP, ')')
            return args
        elseif is(TK.OP, '{') then
            adv()
            -- table literal as arg
            local fields = {}
            while not is(TK.OP, '}') do
                local f
                if is(TK.OP, '[') then
                    adv(); local key = parseExpr(); expect(TK.OP,']'); expect(TK.OP,'=')
                    f = {kind="IndexedField", key=key, value=parseExpr()}
                elseif is(TK.NAME) and peek(1).kind==TK.OP and peek(1).value=='=' then
                    local name = adv().value; adv()
                    f = {kind="NamedField", name=name, value=parseExpr()}
                else
                    f = {kind="ValueField", value=parseExpr()}
                end
                fields[#fields+1] = f
                if not match(TK.OP, ',') then match(TK.OP, ';') end
            end
            expect(TK.OP, '}')
            return {{kind="TableExpr", fields=fields}}
        elseif is(TK.STRING) then
            local s = adv()
            return {{kind="StringExpr", value=s.value}}
        end
        error("Expected call args at line " .. cur().line)
    end

    local function parseTableExpr()
        -- Called after '{' has been consumed
        local fields = {}
        while not is(TK.OP, '}') do
            local f
            if is(TK.OP, '[') then
                adv(); local key = parseExpr(); expect(TK.OP,']'); expect(TK.OP,'=')
                f = {kind="IndexedField", key=key, value=parseExpr()}
            elseif is(TK.NAME) and peek(1).kind==TK.OP and peek(1).value=='=' then
                local name = adv().value; adv()
                f = {kind="NamedField", name=name, value=parseExpr()}
            else
                f = {kind="ValueField", value=parseExpr()}
            end
            fields[#fields+1] = f
            if not match(TK.OP, ',') then match(TK.OP, ';') end
            if is(TK.OP, '}') then break end
        end
        expect(TK.OP, '}')
        return {kind="TableExpr", fields=fields}
    end

    -- ── Primary expressions (with suffix chain) ──────────────
    parsePrimaryExpr = function()
        local base
        if is(TK.NAME) then
            base = {kind="NameExpr", name=adv().value}
        elseif is(TK.OP, '(') then
            adv(); base = {kind="ParenExpr", expr=parseExpr()}; expect(TK.OP, ')')
        else
            local t = cur()
            error(("Unexpected token %s '%s' at line %d"):format(t.kind,tostring(t.value),t.line))
        end

        while true do
            if is(TK.OP, '.') then
                adv(); local f = expect(TK.NAME).value
                base = {kind="FieldExpr", base=base, field=f}
            elseif is(TK.OP, '[') then
                adv(); local key = parseExpr(); expect(TK.OP, ']')
                base = {kind="IndexExpr", base=base, key=key}
            elseif is(TK.OP, ':') then
                adv(); local meth = expect(TK.NAME).value
                local args = parseCallArgs()
                base = {kind="MethodCallExpr", base=base, method=meth, args=args}
            elseif is(TK.OP,'(') or is(TK.OP,'{') or is(TK.STRING) then
                base = {kind="CallExpr", func=base, args=parseCallArgs()}
            else
                break
            end
        end
        return base
    end

    -- ── Simple (atom) expressions ────────────────────────────
    parseSimpleExpr = function()
        local t = cur()
        if t.kind == TK.NUMBER then
            adv(); return {kind="NumberExpr", value=tonumber(t.value), raw=t.value}
        elseif t.kind == TK.STRING then
            adv(); return {kind="StringExpr", value=t.value}
        elseif t.kind == TK.KEYWORD and t.value == "nil" then
            adv(); return {kind="NilExpr"}
        elseif t.kind == TK.KEYWORD and t.value == "true" then
            adv(); return {kind="TrueExpr"}
        elseif t.kind == TK.KEYWORD and t.value == "false" then
            adv(); return {kind="FalseExpr"}
        elseif t.kind == TK.OP and t.value == "..." then
            adv(); return {kind="VarArgExpr"}
        elseif t.kind == TK.KEYWORD and t.value == "function" then
            adv(); return parseFuncBody()
        elseif t.kind == TK.OP and t.value == '{' then
            adv(); return parseTableExpr()
        else
            return parsePrimaryExpr()
        end
    end

    -- ── Binary operator precedence table ─────────────────────
    -- {left-binding, right-binding}  right > left → right-assoc
    local binops = {
        ["or"]={1,1},  ["and"]={2,2},
        ["<"]={3,3},   [">"]={3,3},  ["<="]={3,3}, [">="]={3,3},
        ["=="]={3,3},  ["~="]={3,3},
        ["|"]={4,4},   ["~"]={5,5},  ["&"]={6,6},
        ["<<"]={7,7},  [">>"]={7,7},
        [".."]={8,7},  -- right-assoc
        ["+"]={9,9},   ["-"]={9,9},
        ["*"]={10,10}, ["/"]={10,10},["//"]={10,10},["%"]={10,10},
        ["^"]={12,11}, -- right-assoc
    }
    local unops = {["not"]=11, ["-"]=11, ["#"]=11, ["~"]=11}

    parseExpr = function(limit)
        limit = limit or 0
        local expr
        -- Unary
        local t = cur()
        local uop = (t.kind == TK.KEYWORD or t.kind == TK.OP) and unops[t.value]
        if uop then
            adv(); expr = {kind="UnopExpr", op=t.value, expr=parseExpr(11)}
        else
            expr = parseSimpleExpr()
        end
        -- Binary
        while true do
            local ct = cur()
            local bp = binops[ct.value]
            if not bp or bp[1] <= limit then break end
            if ct.kind ~= TK.OP and ct.kind ~= TK.KEYWORD then break end
            adv()
            expr = {kind="BinopExpr", op=ct.value, left=expr, right=parseExpr(bp[2])}
        end
        return expr
    end

    -- ── Statements ───────────────────────────────────────────
    local blockEnders = {
        ["end"]=true, ["else"]=true, ["elseif"]=true, ["until"]=true
    }

    local function hasControlFlowAt(stmts)
        -- Returns true if any top-level stmt is return/break/continue/goto
        for _, s in ipairs(stmts) do
            local k = s.kind
            if k=="ReturnStat" or k=="BreakStat" or k=="ContinueStat" or k=="GotoStat" then
                return true
            end
        end
        return false
    end

    parseStat = function()
        local t = cur()

        -- semicolon
        if is(TK.OP, ';') then adv(); return nil end

        -- if
        if is(TK.KEYWORD, 'if') then
            adv()
            local cond = parseExpr()
            expect(TK.KEYWORD, 'then')
            local thenBlock = parseBlock()
            local elseifs, elseBlock = {}, nil
            while is(TK.KEYWORD, 'elseif') do
                adv()
                local ec = parseExpr(); expect(TK.KEYWORD,'then')
                elseifs[#elseifs+1] = {cond=ec, block=parseBlock()}
            end
            if match(TK.KEYWORD, 'else') then elseBlock = parseBlock() end
            expect(TK.KEYWORD, 'end')
            return {kind="IfStat", cond=cond, thenBlock=thenBlock, elseifs=elseifs, elseBlock=elseBlock}
        end

        -- while
        if is(TK.KEYWORD, 'while') then
            adv(); local cond = parseExpr(); expect(TK.KEYWORD,'do')
            local block = parseBlock(); expect(TK.KEYWORD,'end')
            return {kind="WhileStat", cond=cond, block=block}
        end

        -- do
        if is(TK.KEYWORD, 'do') then
            adv(); local block = parseBlock(); expect(TK.KEYWORD,'end')
            return {kind="DoStat", block=block}
        end

        -- for
        if is(TK.KEYWORD, 'for') then
            adv()
            local firstName = expect(TK.NAME).value
            if match(TK.OP, '=') then
                local start = parseExpr(); expect(TK.OP,',')
                local stop  = parseExpr()
                local step  = match(TK.OP,',') and parseExpr() or nil
                expect(TK.KEYWORD,'do'); local block = parseBlock(); expect(TK.KEYWORD,'end')
                return {kind="NumericForStat", var=firstName, start=start, stop=stop, step=step, block=block}
            else
                local vars = {firstName}
                while match(TK.OP,',') do vars[#vars+1] = expect(TK.NAME).value end
                expect(TK.KEYWORD,'in')
                local iters = parseExprList()
                expect(TK.KEYWORD,'do'); local block = parseBlock(); expect(TK.KEYWORD,'end')
                return {kind="GenericForStat", vars=vars, iters=iters, block=block}
            end
        end

        -- repeat
        if is(TK.KEYWORD, 'repeat') then
            adv(); local block = parseBlock(); expect(TK.KEYWORD,'until')
            return {kind="RepeatStat", block=block, cond=parseExpr()}
        end

        -- function
        if is(TK.KEYWORD, 'function') then
            adv()
            local base = {kind="NameExpr", name=expect(TK.NAME).value}
            local isMethod = false
            while is(TK.OP,'.') do
                adv(); base = {kind="FieldExpr", base=base, field=expect(TK.NAME).value}
            end
            if is(TK.OP,':') then
                adv(); base = {kind="FieldExpr", base=base, field=expect(TK.NAME).value}
                isMethod = true
            end
            local func = parseFuncBody()
            if isMethod then table.insert(func.params, 1, "self") end
            return {kind="FuncStat", name=base, func=func}
        end

        -- local
        if is(TK.KEYWORD, 'local') then
            adv()
            if is(TK.KEYWORD, 'function') then
                adv()
                local name = expect(TK.NAME).value
                local func = parseFuncBody()
                return {kind="LocalFuncStat", name=name, func=func}
            else
                local names = {expect(TK.NAME).value}
                while match(TK.OP,',') do names[#names+1] = expect(TK.NAME).value end
                local exprs = match(TK.OP,'=') and parseExprList() or {}
                return {kind="LocalStat", names=names, exprs=exprs}
            end
        end

        -- return
        if is(TK.KEYWORD, 'return') then
            adv()
            local values = {}
            local stop = {["end"]=true,["else"]=true,["elseif"]=true,["until"]=true}
            if not (is(TK.EOF) or is(TK.OP,';') or
                   (is(TK.KEYWORD) and stop[cur().value])) then
                values = parseExprList()
            end
            match(TK.OP, ';')
            return {kind="ReturnStat", values=values}
        end

        -- break
        if is(TK.KEYWORD, 'break') then
            adv(); return {kind="BreakStat"}
        end

        -- continue (Luau)
        if is(TK.KEYWORD, 'continue') then
            adv(); return {kind="ContinueStat"}
        end

        -- goto
        if is(TK.KEYWORD, 'goto') then
            adv(); return {kind="GotoStat", label=expect(TK.NAME).value}
        end

        -- label ::name::
        if is(TK.OP, '::') then
            adv(); local name = expect(TK.NAME).value; expect(TK.OP,'::'
            ); return {kind="LabelStat", name=name}
        end

        -- Assignment or function call
        local expr = parsePrimaryExpr()
        if is(TK.OP,'=') or is(TK.OP,',') then
            local targets = {expr}
            while match(TK.OP,',') do targets[#targets+1] = parsePrimaryExpr() end
            expect(TK.OP,'=')
            return {kind="AssignStat", targets=targets, values=parseExprList()}
        end
        if expr.kind == "CallExpr" or expr.kind == "MethodCallExpr" then
            return {kind="CallStat", expr=expr}
        end
        error("Unexpected statement expression at line " .. t.line)
    end

    parseBlock = function()
        local stmts = {}
        while true do
            local t = cur()
            if t.kind == TK.EOF then break end
            if t.kind == TK.KEYWORD and blockEnders[t.value] then break end
            local s = parseStat()
            if s then
                stmts[#stmts+1] = s
                if s.kind == "ReturnStat" then break end
            end
        end
        return {kind="Block", stmts=stmts}
    end

    local function parse(toks)
        tokens = toks; pos = 1
        local block = parseBlock()
        expect(TK.EOF)
        return block
    end

    return { parse = parse }
end)()

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SECTION 6 · NAME GENERATOR                                 ║
-- ╚══════════════════════════════════════════════════════════════╝
local NameGen = (function()
    local used = {}
    local chars = {"l","I","1","O","0"}

    local function makeHomoglyph()
        local len = RNG.int(8, 16)
        local p = {"_"}
        for i = 2, len do p[#p+1] = RNG.pick(chars) end
        return table.concat(p)
    end
    local function makeHex()
        return ("_0x%04X%04X"):format(RNG.int(0,0xFFFF), RNG.int(0,0xFFFF))
    end
    local function makeUnderscore()
        local p = {}
        for i = 1, RNG.int(3,7) do p[#p+1]="_" end
        p[#p+1] = string.char(RNG.int(97,122))
        return table.concat(p)
    end

    local generators = {
        HOMOGLYPH  = makeHomoglyph,
        HEX        = makeHex,
        UNDERSCORE = makeUnderscore,
    }
    local gen = generators[Config.namingStyle] or makeHomoglyph

    local function generate()
        local name; local tries = 0
        repeat
            name = gen(); tries = tries + 1
            if tries > 50000 then error("NameGen: collision saturation") end
        until not used[name]
        used[name] = true
        return name
    end

    local function reset() used = {} end

    return { generate = generate, reset = reset }
end)()

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SECTION 7 · ENCRYPTOR                                      ║
-- ╚══════════════════════════════════════════════════════════════╝
local Encryptor = (function()
    local function toBytes(s)
        local b = {}
        for i = 1, #s do b[i] = string.byte(s, i) end
        return b
    end
    local function xorEnc(bytes, key)
        local out = {}
        for i, b in ipairs(bytes) do
            out[i] = bit32.bxor(b, key[(i-1)%#key+1])
        end
        return out
    end
    local function addEnc(bytes, key)
        local out = {}
        for i, b in ipairs(bytes) do
            out[i] = (b + key[(i-1)%#key+1]) % 256
        end
        return out
    end
    local function genKey(len)
        local k = {}
        for i = 1, len do k[i] = RNG.int(1, 255) end
        return k
    end
    local enc = Config.encryptMode == "ADD" and addEnc or xorEnc
    return { toBytes=toBytes, encrypt=enc, genKey=genKey }
end)()

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SECTION 8 · STRING TABLE                                   ║
-- ╚══════════════════════════════════════════════════════════════╝
local StringTable = (function()
    local entries = {}
    local indexMap = {}
    local key = Encryptor.genKey(RNG.int(8, 20))

    local function intern(s)
        if indexMap[s] then return indexMap[s] end
        local bytes = Encryptor.toBytes(s)
        local enc   = Encryptor.encrypt(bytes, key)
        local idx   = #entries + 1
        entries[idx] = {raw=s, encrypted=enc, index=idx}
        indexMap[s]  = idx
        return idx
    end

    local function getKey()   return key     end
    local function getAll()   return entries end
    local function getCount() return #entries end

    return { intern=intern, getKey=getKey, getAll=getAll, getCount=getCount }
end)()

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SECTION 9 · PASS 1 · IDENTIFIER RENAMING                  ║
-- ╚══════════════════════════════════════════════════════════════╝
local passRename = (function()
    -- Globals / builtins we never touch
    local PROTECTED = {
        print=true,pairs=true,ipairs=true,next=true,error=true,
        assert=true,pcall=true,xpcall=true,rawget=true,rawset=true,
        rawequal=true,rawlen=true,select=true,type=true,tostring=true,
        tonumber=true,setmetatable=true,getmetatable=true,unpack=true,
        table=true,string=true,math=true,io=true,os=true,bit32=true,
        coroutine=true,package=true,require=true,load=true,loadstring=true,
        dofile=true,loadfile=true,collectgarbage=true,_G=true,_ENV=true,
        _VERSION=true,warn=true,utf8=true,task=true,game=true,
        workspace=true,script=true,shared=true,wait=true,spawn=true,
        delay=true,Vector3=true,CFrame=true,Color3=true,Instance=true,
        Enum=true,tick=true,time=true,typeof=true,math=true,
    }

    return function(ast)
        local stack = {{}}  -- scope stack: each frame maps origName → newName

        local function push() stack[#stack+1] = {} end
        local function pop()  stack[#stack] = nil  end
        local function define(name)
            local n = NameGen.generate()
            stack[#stack][name] = n
            return n
        end
        local function resolve(name)
            for i = #stack, 1, -1 do
                if stack[i][name] then return stack[i][name] end
            end
            return nil
        end

        local renameExpr, renameStat, renameBlock

        renameExpr = function(node)
            if not node then return end
            local k = node.kind
            if k == "NameExpr" then
                if not PROTECTED[node.name] then
                    local r = resolve(node.name)
                    if r then node.name = r end
                end
            elseif k == "FuncExpr" then
                push()
                for i, p in ipairs(node.params) do
                    if p ~= "self" and p ~= "..." then
                        node.params[i] = define(p)
                    end
                end
                renameBlock(node.block)
                pop()
            elseif k == "CallExpr" then
                renameExpr(node.func)
                for _, a in ipairs(node.args) do renameExpr(a) end
            elseif k == "MethodCallExpr" then
                renameExpr(node.base)
                for _, a in ipairs(node.args) do renameExpr(a) end
            elseif k == "IndexExpr" then
                renameExpr(node.base); renameExpr(node.key)
            elseif k == "FieldExpr" then
                renameExpr(node.base)  -- .field is a key, not a local
            elseif k == "BinopExpr" then
                renameExpr(node.left); renameExpr(node.right)
            elseif k == "UnopExpr" then
                renameExpr(node.expr)
            elseif k == "TableExpr" then
                for _, f in ipairs(node.fields) do
                    if f.kind == "IndexedField" then
                        renameExpr(f.key); renameExpr(f.value)
                    elseif f.kind == "NamedField" then
                        renameExpr(f.value)
                    elseif f.kind == "ValueField" then
                        renameExpr(f.value)
                    end
                end
            elseif k == "ParenExpr" then
                renameExpr(node.expr)
            end
            -- Leaf nodes: NumberExpr, StringExpr, NilExpr, TrueExpr, FalseExpr, VarArgExpr → no-op
        end

        renameStat = function(node)
            if not node then return end
            local k = node.kind
            if k == "LocalStat" then
                for _, e in ipairs(node.exprs) do renameExpr(e) end  -- RHS first
                for i, name in ipairs(node.names) do
                    node.names[i] = define(name)
                end
            elseif k == "LocalFuncStat" then
                local newName = define(node.name)
                node.name = newName
                push()
                for i, p in ipairs(node.func.params) do
                    if p ~= "self" and p ~= "..." then
                        node.func.params[i] = define(p)
                    end
                end
                renameBlock(node.func.block)
                pop()
            elseif k == "FuncStat" then
                renameExpr(node.name)
                push()
                for i, p in ipairs(node.func.params) do
                    if p ~= "self" and p ~= "..." then
                        node.func.params[i] = define(p)
                    end
                end
                renameBlock(node.func.block)
                pop()
            elseif k == "AssignStat" then
                for _, t in ipairs(node.targets) do renameExpr(t) end
                for _, v in ipairs(node.values)  do renameExpr(v) end
            elseif k == "CallStat" then
                renameExpr(node.expr)
            elseif k == "DoStat" then
                push(); renameBlock(node.block); pop()
            elseif k == "WhileStat" then
                renameExpr(node.cond)
                push(); renameBlock(node.block); pop()
            elseif k == "RepeatStat" then
                push(); renameBlock(node.block); renameExpr(node.cond); pop()
            elseif k == "IfStat" then
                renameExpr(node.cond)
                push(); renameBlock(node.thenBlock); pop()
                for _, ei in ipairs(node.elseifs) do
                    renameExpr(ei.cond)
                    push(); renameBlock(ei.block); pop()
                end
                if node.elseBlock then push(); renameBlock(node.elseBlock); pop() end
            elseif k == "NumericForStat" then
                renameExpr(node.start); renameExpr(node.stop)
                if node.step then renameExpr(node.step) end
                push(); node.var = define(node.var); renameBlock(node.block); pop()
            elseif k == "GenericForStat" then
                for _, it in ipairs(node.iters) do renameExpr(it) end
                push()
                for i, v in ipairs(node.vars) do node.vars[i] = define(v) end
                renameBlock(node.block)
                pop()
            elseif k == "ReturnStat" then
                for _, v in ipairs(node.values) do renameExpr(v) end
            end
        end

        renameBlock = function(block)
            for _, s in ipairs(block.stmts) do renameStat(s) end
        end

        renameBlock(ast)
    end
end)()

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SECTION 10 · PASS 2 · STRING ENCRYPTION                   ║
-- ╚══════════════════════════════════════════════════════════════╝
local passStringEncrypt = (function()
    local decName, cacheName, ctName, ktName  -- obfuscated identifiers

    local function makeDecCall(idx)
        return {
            kind = "CallExpr",
            func = {kind="NameExpr", name=decName},
            args = {{kind="NumberExpr", value=idx, raw=tostring(idx)}}
        }
    end

    -- Replace StringExpr in a field position
    local function replStr(obj, field)
        local v = obj[field]
        if not v or type(v) ~= "table" then return end
        if v.kind == "StringExpr" then
            obj[field] = makeDecCall(StringTable.intern(v.value))
        else
            encryptNode(v)  -- forward ref — defined below
        end
    end

    -- Replace StringExpr in a list
    local function replList(t)
        for i, v in ipairs(t) do
            if v and type(v)=="table" and v.kind == "StringExpr" then
                t[i] = makeDecCall(StringTable.intern(v.value))
            else
                encryptNode(v)
            end
        end
    end

    -- Forward-declared; used by replStr
    function encryptNode(node)
        if not node or type(node) ~= "table" then return end
        local k = node.kind
        if k == "Block" then
            for _, s in ipairs(node.stmts) do encryptNode(s) end
        elseif k == "LocalStat" then
            replList(node.exprs)
        elseif k == "LocalFuncStat" then encryptNode(node.func)
        elseif k == "FuncStat"      then encryptNode(node.func)
        elseif k == "FuncExpr"      then encryptNode(node.block)
        elseif k == "AssignStat" then
            replList(node.targets); replList(node.values)
        elseif k == "CallStat" then
            replStr(node, "expr")
        elseif k == "DoStat"  then encryptNode(node.block)
        elseif k == "WhileStat" then
            replStr(node,"cond"); encryptNode(node.block)
        elseif k == "RepeatStat" then
            encryptNode(node.block); replStr(node,"cond")
        elseif k == "IfStat" then
            replStr(node,"cond"); encryptNode(node.thenBlock)
            for _, ei in ipairs(node.elseifs) do
                replStr(ei,"cond"); encryptNode(ei.block)
            end
            if node.elseBlock then encryptNode(node.elseBlock) end
        elseif k == "NumericForStat" then
            replStr(node,"start"); replStr(node,"stop")
            if node.step then replStr(node,"step") end
            encryptNode(node.block)
        elseif k == "GenericForStat" then
            replList(node.iters); encryptNode(node.block)
        elseif k == "ReturnStat" then
            replList(node.values)
        elseif k == "CallExpr" then
            replStr(node,"func"); replList(node.args)
        elseif k == "MethodCallExpr" then
            encryptNode(node.base); replList(node.args)
        elseif k == "IndexExpr" then
            replStr(node,"base"); replStr(node,"key")
        elseif k == "FieldExpr" then
            encryptNode(node.base)
        elseif k == "BinopExpr" then
            replStr(node,"left"); replStr(node,"right")
        elseif k == "UnopExpr" then
            replStr(node,"expr")
        elseif k == "TableExpr" then
            for _, f in ipairs(node.fields) do
                if f.kind=="IndexedField" then
                    replStr(f,"key"); replStr(f,"value")
                elseif f.kind=="NamedField"  then replStr(f,"value")
                elseif f.kind=="ValueField"  then replStr(f,"value")
                end
            end
        elseif k == "ParenExpr" then
            replStr(node,"expr")
        end
        -- Leaf nodes: NameExpr, NumberExpr, NilExpr, etc. → no string children
    end

    local function buildPreamble()
        local entries = StringTable.getAll()
        local key     = StringTable.getKey()

        -- Key array
        local kp = {}
        for _, b in ipairs(key) do kp[#kp+1] = tostring(b) end

        -- Encrypted string table
        local cp = {}
        for _, entry in ipairs(entries) do
            local ep = {}
            for _, b in ipairs(entry.encrypted) do ep[#ep+1] = tostring(b) end
            cp[#cp+1] = "{" .. table.concat(ep, ",") .. "}"
        end

        -- Decode expression per mode
        local decExpr
        if Config.encryptMode == "ADD" then
            decExpr = ("((b[j]+%s[(j-1)%%%s+1])%%256)"):format(ktName, "#"..ktName)
        else
            decExpr = ("bit32.bxor(b[j],%s[(j-1)%%%s+1])"):format(ktName, "#"..ktName)
        end

        local lines = {
            ("local %s={%s}"):format(ktName, table.concat(kp,",")),
            ("local %s={%s}"):format(ctName, table.concat(cp,",")),
            ("local %s={}"):format(cacheName),
            ("local %s=function(i)"):format(decName),
            ("  if %s[i] then return %s[i] end"):format(cacheName, cacheName),
            ("  local b,r=%s[i],{}"):format(ctName),
            ("  for j=1,#b do r[j]=string.char(%s) end"):format(decExpr),
            ("  %s[i]=table.concat(r) return %s[i]"):format(cacheName, cacheName),
            "end",
        }
        return table.concat(lines, "\n")
    end

    return function(ast)
        decName   = NameGen.generate()
        cacheName = NameGen.generate()
        ctName    = NameGen.generate()
        ktName    = NameGen.generate()

        encryptNode(ast)

        ast._preamble  = buildPreamble()
        ast._decName   = decName
        ast._ctName    = ctName  -- needed by anti-tamper
    end
end)()

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SECTION 11 · PASS 3 · CONSTANT ENCODING                   ║
-- ╚══════════════════════════════════════════════════════════════╝
local passConstantEncode = (function()
    local function N(v)  return {kind="NumberExpr", value=v, raw=tostring(v)} end
    local function name(n) return {kind="NameExpr", name=n} end

    local function encodeInt(n)
        -- Never encode 0 or 1 — no benefit
        if n == 0 or n == 1 then return N(n) end
        local choice = RNG.int(1, 4)
        local abs_n = math.abs(math.floor(n))

        if choice == 1 then
            -- n = a + b
            local a = RNG.int(1, math.max(1, abs_n - 1)) * (n < 0 and -1 or 1)
            local b = n - a
            return {kind="BinopExpr", op="+", left=N(a), right=N(b)}

        elseif choice == 2 then
            -- n = a - b  →  store (n+b) and b
            local b = RNG.int(1, 50)
            return {kind="BinopExpr", op="-", left=N(n+b), right=N(b)}

        elseif choice == 3 and n >= 0 and n < 2^24 then
            -- XOR: n = bit32.bxor(n XOR mask, mask)
            local mask = RNG.int(1, 255)
            local xored = bit32.bxor(math.floor(n), mask)
            return {kind="CallExpr",
                func={kind="FieldExpr", base=name("bit32"), field="bxor"},
                args={N(xored), N(mask)}}

        else
            -- n = a * b if factorizable, else fallback
            if abs_n > 2 then
                for try = 2, 7 do
                    if abs_n % try == 0 then
                        local a = try * (n<0 and -1 or 1)
                        local b = math.abs(n) // try
                        return {kind="BinopExpr", op="*", left=N(a), right=N(b)}
                    end
                end
            end
            local a = RNG.int(1, math.max(1, abs_n))
            return {kind="BinopExpr", op="+", left=N(a), right=N(n-a)}
        end
    end

    local function encodeNum(v)
        if v ~= math.floor(v) then
            -- Float: represent as integer division
            local scale = 10000
            local a = math.floor(v * scale)
            return {kind="BinopExpr", op="/", left=N(a), right=N(scale)}
        end
        return encodeInt(v)
    end

    local function replNum(obj, field)
        local v = obj[field]
        if not v or type(v)~="table" then return end
        if v.kind == "NumberExpr" and v.value ~= nil then
            obj[field] = encodeNum(v.value)
        else
            processConst(v)
        end
    end

    local function replNumList(t)
        for i, v in ipairs(t) do
            if v and type(v)=="table" and v.kind=="NumberExpr" and v.value~=nil then
                t[i] = encodeNum(v.value)
            else
                processConst(v)
            end
        end
    end

    function processConst(node)
        if not node or type(node)~="table" then return end
        local k = node.kind
        if k=="Block" then
            for _,s in ipairs(node.stmts) do processConst(s) end
        elseif k=="LocalStat"     then replNumList(node.exprs)
        elseif k=="LocalFuncStat" then processConst(node.func)
        elseif k=="FuncStat"      then processConst(node.func)
        elseif k=="FuncExpr"      then processConst(node.block)
        elseif k=="AssignStat" then
            replNumList(node.targets); replNumList(node.values)
        elseif k=="CallStat"  then processConst(node.expr)
        elseif k=="DoStat"    then processConst(node.block)
        elseif k=="WhileStat" then
            replNum(node,"cond"); processConst(node.block)
        elseif k=="RepeatStat" then
            processConst(node.block); replNum(node,"cond")
        elseif k=="IfStat" then
            replNum(node,"cond"); processConst(node.thenBlock)
            for _,ei in ipairs(node.elseifs) do
                replNum(ei,"cond"); processConst(ei.block)
            end
            if node.elseBlock then processConst(node.elseBlock) end
        elseif k=="NumericForStat" then
            replNum(node,"start"); replNum(node,"stop")
            if node.step then replNum(node,"step") end
            processConst(node.block)
        elseif k=="GenericForStat" then
            replNumList(node.iters); processConst(node.block)
        elseif k=="ReturnStat" then replNumList(node.values)
        elseif k=="CallExpr" then
            processConst(node.func); replNumList(node.args)
        elseif k=="MethodCallExpr" then
            processConst(node.base); replNumList(node.args)
        elseif k=="IndexExpr" then
            processConst(node.base); replNum(node,"key")
        elseif k=="FieldExpr"  then processConst(node.base)
        elseif k=="BinopExpr" then
            replNum(node,"left"); replNum(node,"right")
        elseif k=="UnopExpr"  then replNum(node,"expr")
        elseif k=="ParenExpr" then replNum(node,"expr")
        elseif k=="TableExpr" then
            for _,f in ipairs(node.fields) do
                if f.kind=="IndexedField" then
                    replNum(f,"key"); replNum(f,"value")
                elseif f.kind=="NamedField"  then replNum(f,"value")
                elseif f.kind=="ValueField"  then replNum(f,"value")
                end
            end
        end
    end

    return function(ast) processConst(ast) end
end)()

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SECTION 12 · PASS 4 · CONTROL FLOW FLATTENING             ║
-- ╚══════════════════════════════════════════════════════════════╝
local passControlFlow = (function()
    local function N(v) return {kind="NumberExpr",value=v,raw=tostring(v)} end
    local function Nm(n) return {kind="NameExpr",name=n} end

    local function hasControlFlow(stmts)
        for _, s in ipairs(stmts) do
            local k = s.kind
            if k=="ReturnStat" or k=="BreakStat" or k=="ContinueStat" or k=="GotoStat" then
                return true
            end
        end
        return false
    end

    local function flattenBlock(block)
        local stmts = block.stmts
        -- Safety: skip if too small or has control-flow statements
        if #stmts < 4 or hasControlFlow(stmts) then return end

        local numChunks = RNG.int(2, math.min(6, math.floor(#stmts/2)))
        local chunkSize = math.ceil(#stmts / numChunks)

        -- Split into chunks
        local chunks = {}
        local i = 1
        while i <= #stmts do
            local chunk = {}
            for j = i, math.min(i + chunkSize - 1, #stmts) do
                chunk[#chunk+1] = stmts[j]
            end
            chunks[#chunks+1] = chunk
            i = i + chunkSize
        end

        -- Assign randomised state numbers
        local stateOf = {}
        local used = {}
        for ci = 1, #chunks do
            local s
            repeat s = RNG.int(10, 9999) until not used[s]
            used[s] = true; stateOf[ci] = s
        end
        local DONE = 0

        local sv = NameGen.generate()  -- state variable
        local dt = NameGen.generate()  -- dispatch table

        local new = {}

        -- local sv = stateOf[1]
        new[#new+1] = {kind="LocalStat",names={sv},exprs={N(stateOf[1])}}
        -- local dt = {}
        new[#new+1] = {kind="LocalStat",names={dt},exprs={{kind="TableExpr",fields={}}}}

        -- dt[stateOf[ci]] = function() <chunk> sv = nextState end
        for ci = 1, #chunks do
            local nextS = (ci < #chunks) and stateOf[ci+1] or DONE
            local body  = {}
            for _, s in ipairs(chunks[ci]) do body[#body+1] = s end
            body[#body+1] = {
                kind="AssignStat",
                targets={{kind="NameExpr",name=sv}},
                values={N(nextS)}
            }
            new[#new+1] = {
                kind="AssignStat",
                targets={{kind="IndexExpr",base=Nm(dt),key=N(stateOf[ci])}},
                values={{kind="FuncExpr",params={},hasVarArg=false,
                         block={kind="Block",stmts=body}}}
            }
        end

        -- while sv ~= 0 do dt[sv]() end
        new[#new+1] = {
            kind="WhileStat",
            cond={kind="BinopExpr",op="~=",left=Nm(sv),right=N(DONE)},
            block={kind="Block",stmts={{
                kind="CallStat",
                expr={kind="CallExpr",
                    func={kind="IndexExpr",base=Nm(dt),key=Nm(sv)},
                    args={}}
            }}}
        }

        block.stmts = new
    end

    local function processNode(node)
        if not node or type(node)~="table" then return end
        local k = node.kind
        if k=="FuncExpr" then
            processNode(node.block)
            flattenBlock(node.block)
        elseif k=="LocalFuncStat" then processNode(node.func)
        elseif k=="FuncStat"      then processNode(node.func)
        elseif k=="Block" then
            for _,s in ipairs(node.stmts) do processNode(s) end
        elseif k=="DoStat" then
            processNode(node.block); flattenBlock(node.block)
        elseif k=="WhileStat"  or k=="RepeatStat" then processNode(node.block)
        elseif k=="IfStat" then
            processNode(node.thenBlock)
            for _,ei in ipairs(node.elseifs) do processNode(ei.block) end
            if node.elseBlock then processNode(node.elseBlock) end
        elseif k=="NumericForStat" or k=="GenericForStat" then processNode(node.block)
        end
    end

    return function(ast)
        processNode(ast)
        flattenBlock(ast)  -- flatten root block too
    end
end)()

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SECTION 13 · PASS 5 · JUNK INJECTION                      ║
-- ╚══════════════════════════════════════════════════════════════╝
local passJunkInject = (function()
    local density = {LOW=8, MEDIUM=3, HIGH=1}

    local function N(v) return {kind="NumberExpr",value=v,raw=tostring(v)} end
    local function Nm(n) return {kind="NameExpr",name=n} end

    local function junk()
        local jn = NameGen.generate()
        local choice = RNG.int(1, 6)
        if choice == 1 then
            -- local jn = math.floor(0)
            return {kind="LocalStat",names={jn},exprs={{
                kind="CallExpr",
                func={kind="FieldExpr",base=Nm("math"),field="floor"},
                args={N(0)}}}}
        elseif choice == 2 then
            -- if false then local jn = <n> end
            return {kind="IfStat",
                cond={kind="FalseExpr"},
                thenBlock={kind="Block",stmts={{
                    kind="LocalStat",names={jn},exprs={N(RNG.int(0,999))}}}},
                elseifs={},elseBlock=nil}
        elseif choice == 3 then
            -- local jn = bit32.bxor(0xFF,0xFF)
            return {kind="LocalStat",names={jn},exprs={{
                kind="CallExpr",
                func={kind="FieldExpr",base=Nm("bit32"),field="bxor"},
                args={N(0xFF), N(0xFF)}}}}
        elseif choice == 4 then
            -- local jn = type(nil)
            return {kind="LocalStat",names={jn},exprs={{
                kind="CallExpr",func=Nm("type"),args={{kind="NilExpr"}}}}}
        elseif choice == 5 then
            -- local jn = (1+1==2) and 0 or 0
            return {kind="LocalStat",names={jn},exprs={{
                kind="BinopExpr",op="and",
                left={kind="BinopExpr",op="==",
                    left={kind="BinopExpr",op="+",left=N(1),right=N(1)},
                    right=N(2)},
                right={kind="BinopExpr",op="or",left=N(0),right=N(0)}}}}
        else
            -- if (1~=1) then error("") end
            return {kind="IfStat",
                cond={kind="BinopExpr",op="~=",left=N(1),right=N(1)},
                thenBlock={kind="Block",stmts={{kind="CallStat",
                    expr={kind="CallExpr",func=Nm("error"),
                          args={{kind="StringExpr",value=""}}}}}},
                elseifs={},elseBlock=nil}
        end
    end

    local function injectInto(block, every)
        local new = {}
        for i, s in ipairs(block.stmts) do
            if i % every == 0 and RNG.chance(80) then
                new[#new+1] = junk()
            end
            new[#new+1] = s
        end
        if RNG.chance(50) then table.insert(new, 1, junk()) end
        block.stmts = new
    end

    local function processNode(node, every)
        if not node or type(node)~="table" then return end
        local k = node.kind
        if k=="Block" then
            injectInto(node, every)
            for _,s in ipairs(node.stmts) do processNode(s, every) end
        elseif k=="FuncExpr"      then processNode(node.block, every)
        elseif k=="LocalFuncStat" then processNode(node.func, every)
        elseif k=="FuncStat"      then processNode(node.func, every)
        elseif k=="DoStat"        then processNode(node.block, every)
        elseif k=="WhileStat"     then processNode(node.block, every)
        elseif k=="RepeatStat"    then processNode(node.block, every)
        elseif k=="IfStat" then
            processNode(node.thenBlock, every)
            for _,ei in ipairs(node.elseifs) do processNode(ei.block, every) end
            if node.elseBlock then processNode(node.elseBlock, every) end
        elseif k=="NumericForStat" or k=="GenericForStat" then
            processNode(node.block, every)
        end
    end

    return function(ast)
        local every = density[Config.junkDensity] or 3
        processNode(ast, every)
    end
end)()

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SECTION 14 · PASS 6 · ANTI-TAMPER                         ║
-- ╚══════════════════════════════════════════════════════════════╝
local passAntitamper = (function()
    local function computeChecksum(entries)
        local h = 0x12345678
        for _, entry in ipairs(entries) do
            for _, b in ipairs(entry.encrypted) do
                h = bit32.bxor(h * 31 + b, h)
                h = bit32.band(h, 0xFFFFFFFF)
            end
        end
        return h
    end

    return function(ast)
        local entries = StringTable.getAll()
        if #entries == 0 then return end

        local expected = computeChecksum(entries)
        local chkFn    = NameGen.generate()
        local ctRef    = ast._ctName or "_C"

        local resp = Config.tamperResponse
        local tamperCode
        if resp == "ERROR" then
            tamperCode = 'error("fatal")'
        elseif resp == "CORRUPT" then
            tamperCode = ctRef .. '[1]={}'
        else
            tamperCode = 'while true do end'
        end

        -- Build the anti-tamper source block
        -- It will be appended to the existing preamble
        local src = table.concat({
            ("local function %s(t)"):format(chkFn),
            "  local h=0x12345678",
            "  for i=1,#t do for j=1,#t[i] do",
            "    h=bit32.bxor(h*31+t[i][j],h)",
            "    h=bit32.band(h,0xFFFFFFFF)",
            "  end end",
            "  return h",
            "end",
            ("if %s(%s)~=%d then %s end"):format(chkFn, ctRef, expected, tamperCode),
        }, "\n")

        ast._preamble = (ast._preamble or "") .. "\n" .. src
    end
end)()

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SECTION 15 · PASS 7 · RUNTIME INTEGRITY                   ║
-- ╚══════════════════════════════════════════════════════════════╝
local passRuntimeIntegrity = (function()
    return function(ast)
        local sigVar = NameGen.generate()
        local sig = RNG.int(0x1000, 0xFFFF)

        -- Append a locked config table and a build-signature comment
        local src = table.concat({
            ("local %s=%d"):format(sigVar, sig),
            ("--[[OBF:SIG=%x|MODE=%s|TS=%d]]"):format(sig, Config.encryptMode, os.time()),
        }, "\n")

        ast._preamble = (ast._preamble or "") .. "\n" .. src
    end
end)()

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SECTION 16 · CODE GENERATOR                                ║
-- ╚══════════════════════════════════════════════════════════════╝
local Generator = (function()
    local buf, ind

    local function E(s)   buf[#buf+1] = s end
    local function EL(s)  buf[#buf+1] = (s or "") .. "\n" end
    local function I()    buf[#buf+1] = string.rep("  ", ind) end
    local function IE(s)  I(); E(s) end
    local function IEL(s) I(); EL(s) end

    local emitExpr, emitStat, emitBlock

    -- ── Expressions ──────────────────────────────────────────
    emitExpr = function(node)
        if not node then E("nil"); return end
        local k = node.kind

        if k == "NumberExpr" then
            local v = node.value
            -- Emit as integer if it has no fractional part
            if v == math.floor(v) and math.abs(v) < 2^53 then
                E(("%d"):format(v))
            else
                E(tostring(v))
            end

        elseif k == "StringExpr" then
            local s = node.value
            s = s:gsub('\\','\\\\'):gsub('"','\\"')
                 :gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t')
                 :gsub('\0','\\0')
            E('"' .. s .. '"')

        elseif k == "NilExpr"   then E("nil")
        elseif k == "TrueExpr"  then E("true")
        elseif k == "FalseExpr" then E("false")
        elseif k == "VarArgExpr" then E("...")

        elseif k == "NameExpr" then
            E(node.name)

        elseif k == "ParenExpr" then
            E("("); emitExpr(node.expr); E(")")

        elseif k == "FieldExpr" then
            emitExpr(node.base); E("."); E(node.field)

        elseif k == "IndexExpr" then
            emitExpr(node.base); E("["); emitExpr(node.key); E("]")

        elseif k == "MethodCallExpr" then
            emitExpr(node.base); E(":"); E(node.method); E("(")
            for i, a in ipairs(node.args) do
                emitExpr(a); if i < #node.args then E(",") end
            end
            E(")")

        elseif k == "CallExpr" then
            emitExpr(node.func); E("(")
            for i, a in ipairs(node.args) do
                emitExpr(a); if i < #node.args then E(",") end
            end
            E(")")

        elseif k == "BinopExpr" then
            local op = node.op
            E("("); emitExpr(node.left)
            if op == "and" or op == "or" then E(" "..op.." ")
            elseif op == ".." then E("..")
            else E(op) end
            emitExpr(node.right); E(")")

        elseif k == "UnopExpr" then
            local op = node.op
            if op == "not" then E("not(")
            elseif op == "-" then E("-(")
            elseif op == "#" then E("#(")
            elseif op == "~" then E("~(")
            end
            emitExpr(node.expr); E(")")

        elseif k == "FuncExpr" then
            E("function(")
            for i, p in ipairs(node.params) do
                E(p); if i < #node.params then E(",") end
            end
            if node.hasVarArg then
                if #node.params > 0 then E(",") end; E("...")
            end
            EL(")")
            ind = ind + 1; emitBlock(node.block); ind = ind - 1
            IE("end")

        elseif k == "TableExpr" then
            E("{")
            for i, f in ipairs(node.fields) do
                if f.kind == "IndexedField" then
                    E("["); emitExpr(f.key); E("]="); emitExpr(f.value)
                elseif f.kind == "NamedField" then
                    E(f.name .. "="); emitExpr(f.value)
                elseif f.kind == "ValueField" then
                    emitExpr(f.value)
                end
                if i < #node.fields then E(",") end
            end
            E("}")

        else
            E("--[[?EXPR:"..tostring(k).."]]nil")
        end
    end

    -- ── Statements ───────────────────────────────────────────
    emitStat = function(node)
        if not node then return end
        local k = node.kind

        if k == "LocalStat" then
            IE("local "); E(table.concat(node.names, ","))
            if #node.exprs > 0 then
                E("=")
                for i, e in ipairs(node.exprs) do
                    emitExpr(e); if i < #node.exprs then E(",") end
                end
            end
            EL()

        elseif k == "LocalFuncStat" then
            IE("local function "); E(node.name); E("(")
            local p = node.func.params
            for i, pm in ipairs(p) do E(pm); if i<#p then E(",") end end
            if node.func.hasVarArg then if #p>0 then E(",") end; E("...") end
            EL(")")
            ind=ind+1; emitBlock(node.func.block); ind=ind-1
            IEL("end")

        elseif k == "FuncStat" then
            IE("function "); emitExpr(node.name); E("(")
            local p = node.func.params
            for i, pm in ipairs(p) do E(pm); if i<#p then E(",") end end
            if node.func.hasVarArg then if #p>0 then E(",") end; E("...") end
            EL(")")
            ind=ind+1; emitBlock(node.func.block); ind=ind-1
            IEL("end")

        elseif k == "AssignStat" then
            I()
            for i, t in ipairs(node.targets) do
                emitExpr(t); if i<#node.targets then E(",") end
            end
            E("=")
            for i, v in ipairs(node.values) do
                emitExpr(v); if i<#node.values then E(",") end
            end
            EL()

        elseif k == "CallStat" then
            I(); emitExpr(node.expr); EL()

        elseif k == "DoStat" then
            IEL("do"); ind=ind+1; emitBlock(node.block); ind=ind-1; IEL("end")

        elseif k == "WhileStat" then
            IE("while "); emitExpr(node.cond); EL(" do")
            ind=ind+1; emitBlock(node.block); ind=ind-1; IEL("end")

        elseif k == "RepeatStat" then
            IEL("repeat")
            ind=ind+1; emitBlock(node.block); ind=ind-1
            IE("until "); emitExpr(node.cond); EL()

        elseif k == "IfStat" then
            IE("if "); emitExpr(node.cond); EL(" then")
            ind=ind+1; emitBlock(node.thenBlock); ind=ind-1
            for _, ei in ipairs(node.elseifs) do
                IE("elseif "); emitExpr(ei.cond); EL(" then")
                ind=ind+1; emitBlock(ei.block); ind=ind-1
            end
            if node.elseBlock then
                IEL("else"); ind=ind+1; emitBlock(node.elseBlock); ind=ind-1
            end
            IEL("end")

        elseif k == "NumericForStat" then
            IE("for "); E(node.var); E("=")
            emitExpr(node.start); E(","); emitExpr(node.stop)
            if node.step then E(","); emitExpr(node.step) end
            EL(" do"); ind=ind+1; emitBlock(node.block); ind=ind-1; IEL("end")

        elseif k == "GenericForStat" then
            IE("for "); E(table.concat(node.vars, ",")); E(" in ")
            for i, it in ipairs(node.iters) do
                emitExpr(it); if i<#node.iters then E(",") end
            end
            EL(" do"); ind=ind+1; emitBlock(node.block); ind=ind-1; IEL("end")

        elseif k == "ReturnStat" then
            IE("return ")
            for i, v in ipairs(node.values) do
                emitExpr(v); if i<#node.values then E(",") end
            end
            EL()

        elseif k == "BreakStat"    then IEL("break")
        elseif k == "ContinueStat" then IEL("continue")
        elseif k == "GotoStat"     then IEL("goto " .. node.label)
        elseif k == "LabelStat"    then IEL("::" .. node.name .. "::")
        else
            IEL("--[[?STAT:" .. tostring(k) .. "]]")
        end
    end

    emitBlock = function(block)
        for _, s in ipairs(block.stmts) do emitStat(s) end
    end

    local function generate(ast)
        buf = {}; ind = 0

        -- Preamble (decoder + anti-tamper + integrity)
        if ast._preamble and #ast._preamble > 0 then
            E(ast._preamble); EL()
        end

        -- Main block
        emitBlock(ast)

        return table.concat(buf)
    end

    return { generate = generate }
end)()

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SECTION 17 · PIPELINE                                      ║
-- ╚══════════════════════════════════════════════════════════════╝
local function obfuscate(source)
    -- Reset name generator for a clean build
    NameGen.reset()

    -- ── Stage 1–2: Lex + Parse ───────────────────────────────
    local tokens = Lexer.tokenize(source)
    local ast    = Parser.parse(tokens)

    -- ── Stage 3: Identifier renaming ─────────────────────────
    passRename(ast)

    -- ── Stage 4: String encryption ───────────────────────────
    passStringEncrypt(ast)

    -- ── Stage 5: Constant encoding ───────────────────────────
    if Config.encodeConsts then
        passConstantEncode(ast)
    end

    -- ── Stage 6: Control flow flattening ─────────────────────
    if Config.flattenFlow then
        passControlFlow(ast)
    end

    -- ── Stage 7: Junk injection ───────────────────────────────
    if Config.injectJunk then
        passJunkInject(ast)
    end

    -- ── Stage 8: Anti-tamper ─────────────────────────────────
    if Config.antiTamper then
        passAntitamper(ast)
    end

    -- ── Stage 9: Runtime integrity preamble ──────────────────
    if Config.integrityLayer then
        passRuntimeIntegrity(ast)
    end

    -- ── Stage 10: Code generation ────────────────────────────
    return Generator.generate(ast)
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SECTION 18 · ENTRY POINT                                   ║
-- ╚══════════════════════════════════════════════════════════════╝

--[[ ── USAGE ─────────────────────────────────────────────────────
  Inline:   Replace the string below with your source.
  Executor: Swap the assignment to:
              local inputSource = readfile("your_script.lua")
  Output:   Change print(result) to writefile("out.lua", result)
──────────────────────────────────────────────────────────────── ]]

local inputSource = [==[
-- Example input
local function greet(name)
    local msg = "Hello, " .. name .. "!"
    print(msg)
end

local players = {"Alice", "Bob", "Charlie"}
for i, player in ipairs(players) do
    greet(player)
end

local function add(a, b)
    return a + b
end

local result = add(10, 32)
print("Sum:", result)
]==]

-- Load from file instead (uncomment if using an executor with readfile):
-- local inputSource = readfile("input.lua")

local ok, result = pcall(obfuscate, inputSource)
if ok then
    print(result)
    -- writefile("output.luau", result)  -- uncomment to save
else
    print("[Obfuscator Error] " .. tostring(result))
end
