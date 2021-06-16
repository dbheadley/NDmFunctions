function byteNum = ByteSizeLUT(precID)

switch precID
    case 'uint'
        byteNum = 4;
    case 'uint8'
        byteNum = 1;
    case 'uint16' 
        byteNum = 2;
    case 'uint32' 
        byteNum = 4;
    case 'uint64' 
        byteNum = 8;
    case 'int'
        byteNum = 4;
    case 'int8'
        byteNum = 1;
    case 'int16' 
        byteNum = 2;
    case 'int32' 
        byteNum = 4;
    case 'int64' 
        byteNum = 8;
    case 'double' 
        byteNum = 8;
    case 'float' 
        byteNum = 4;   
    otherwise
        byteNum = nan;
end
