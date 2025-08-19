local globals = {}

function globals.SetVar(name, value)
    globals[name] = value
end

function globals.GetVar(name)
    return globals[name]
end

return globals