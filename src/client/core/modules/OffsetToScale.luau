function OffsetToScale(arg1: number | UDim2, arg2: number | "X" | "Y")
    if typeof(arg1) == "UDim2" then
        print(arg1.X.Scale + arg1.X.Offset/1920, arg1.Y.Scale + arg1.Y.Offset/1080)
        return UDim2.new(arg1.X.Scale + arg1.X.Offset/1920, 0, arg1.Y.Scale + arg1.Y.Offset/1080, 0)
    elseif arg2 == "X" then
        arg1 = arg1/1920
    elseif arg2 == "Y" then
        arg1 = arg1/1080
    else
        error('OffsetToScale function arg2 was not a number, UDim2, or a string "X" or "Y"')
    end
    return arg1
end

return OffsetToScale