+RegisterNetEvent("rent:vozilo", function(model, cijena)
    local src = source
    local Player = nil
    local hasMoney = false

    if Config.Framework == "ESX" then
        local ESX = exports["es_extended"]:getSharedObject()
        Player = ESX.GetPlayerFromId(src)
        if Player.getMoney() >= cijena then
            Player.removeMoney(cijena)
            hasMoney = true
        end
    elseif Config.Framework == "QB" then
        local QBCore = exports["qb-core"]:GetCoreObject()
        Player = QBCore.Functions.GetPlayer(src)
        if Player.PlayerData.money.cash >= cijena then
            Player.Functions.RemoveMoney("cash", cijena)
            hasMoney = true
        end
    end

    if hasMoney then
        -- Dodaj ugovor u ox_inventory
        exports.ox_inventory:AddItem(src, 'rental_contract', 1, {
            model = model,
            expire = os.time() + 1800 -- 30 minuta
        })

        TriggerClientEvent("rent:spawnVozilo", src, model)

        -- Spremi u bazu
        local ime = GetPlayerName(src)
        MySQL.insert(
            "INSERT INTO rent_vozila (igrac_id, igrac_ime, model, cijena) VALUES (?, ?, ?, ?)",
            {tostring(src), ime, model, cijena}
        )
    else
        TriggerClientEvent("chat:addMessage", src, {args={"RENT", "Nemaš dovoljno novca!"}})
    end
end)


CreateThread(function()
    while true do
        Wait(60000) -- provjera svakih 60 sekundi
        local result = MySQL.query.await('SELECT * FROM rent_vozila')
        for _, v in pairs(result) do
            -- dobivanje ugovora iz ox_inventory
            local items = exports.ox_inventory:Search('slots', 'rental_contract', v.igrac_id)
            local ugovorIstekao = true

            for _, item in pairs(items) do
                if item.metadata and item.metadata.expire and os.time() < item.metadata.expire then
                    ugovorIstekao = false
                end
            end

            if ugovorIstekao then
                -- pošalji klijentu da despawna vozilo
                TriggerClientEvent("rent:despawnVozilo", tonumber(v.igrac_id), v.model)
                
                -- izbriši iz baze
                MySQL.update('DELETE FROM rent_vozila WHERE id = ?', {v.id})
            end
        end
    end
end)
