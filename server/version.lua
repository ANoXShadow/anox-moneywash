local resourceName = GetCurrentResourceName()
local currentVersion = GetResourceMetadata(resourceName, 'version', 0)

CreateThread(function()
    PerformHttpRequest("https://raw.githubusercontent.com/ANoXShadow/anox-moneywash/main/version.txt", function(err, latestVersion, headers)
        if not latestVersion or latestVersion == "" then
            print("^1[" .. resourceName .. "] Failed to check for updates. Could not fetch version.txt^0")
            return
        end

        latestVersion = latestVersion:gsub("%s+", "")

        if currentVersion ~= latestVersion then
            print("^1[" .. resourceName .. "] Your version (" .. currentVersion .. ") is outdated!^0")
            print("^1Latest version: " .. latestVersion .. "^0")
            print("^1Download the latest version: https://github.com/ANoXShadow/anox-moneywash^0")
        else
            print("^2[" .. resourceName .. "] You are running the latest version (" .. currentVersion .. ")^0")
        end
    end, "GET")
end)