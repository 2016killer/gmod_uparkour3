print('test.lua')



if SERVER then
    util.AddNetworkString('TEST')

    local a = {1, 2, 3, {1, 2, 3}}
    net.Start('TEST')
        net.WriteTable(a)

        a[1] = 'hello'
        a[4][1] = 'world'
    net.Send(Entity(1))

    PrintTable(a)
else
    net.Receive('TEST', function(len, ply)
        local a = net.ReadTable()
        PrintTable(a)
    end)
    
end
