--[[                                                --------------------------------->     FOR ASSISTANCE,SCRIPTS AND MORE JOIN OUR DISCORD (https://discord.gg/gbJ5SyBJBv) <---------------------------------                                                                                                                                                                                    
                                                                                                                                                                                                                                 
               AAA               NNNNNNNN        NNNNNNNN                 XXXXXXX       XXXXXXX   SSSSSSSSSSSSSSS TTTTTTTTTTTTTTTTTTTTTTTUUUUUUUU     UUUUUUUUDDDDDDDDDDDDD      IIIIIIIIII     OOOOOOOOO        SSSSSSSSSSSSSSS 
              A:::A              N:::::::N       N::::::N                 X:::::X       X:::::X SS:::::::::::::::ST:::::::::::::::::::::TU::::::U     U::::::UD::::::::::::DDD   I::::::::I   OO:::::::::OO    SS:::::::::::::::S
             A:::::A             N::::::::N      N::::::N                 X:::::X       X:::::XS:::::SSSSSS::::::ST:::::::::::::::::::::TU::::::U     U::::::UD:::::::::::::::DD I::::::::I OO:::::::::::::OO S:::::SSSSSS::::::S
            A:::::::A            N:::::::::N     N::::::N                 X::::::X     X::::::XS:::::S     SSSSSSST:::::TT:::::::TT:::::TUU:::::U     U:::::UUDDD:::::DDDDD:::::DII::::::IIO:::::::OOO:::::::OS:::::S     SSSSSSS
           A:::::::::A           N::::::::::N    N::::::N   ooooooooooo   XXX:::::X   X:::::XXXS:::::S            TTTTTT  T:::::T  TTTTTT U:::::U     U:::::U   D:::::D    D:::::D I::::I  O::::::O   O::::::OS:::::S            
          A:::::A:::::A          N:::::::::::N   N::::::N oo:::::::::::oo    X:::::X X:::::X   S:::::S                    T:::::T         U:::::D     D:::::U   D:::::D     D:::::DI::::I  O:::::O     O:::::OS:::::S            
         A:::::A A:::::A         N:::::::N::::N  N::::::No:::::::::::::::o    X:::::X:::::X     S::::SSSS                 T:::::T         U:::::D     D:::::U   D:::::D     D:::::DI::::I  O:::::O     O:::::O S::::SSSS         
        A:::::A   A:::::A        N::::::N N::::N N::::::No:::::ooooo:::::o     X:::::::::X       SS::::::SSSSS            T:::::T         U:::::D     D:::::U   D:::::D     D:::::DI::::I  O:::::O     O:::::O  SS::::::SSSSS    
       A:::::A     A:::::A       N::::::N  N::::N:::::::No::::o     o::::o     X:::::::::X         SSS::::::::SS          T:::::T         U:::::D     D:::::U   D:::::D     D:::::DI::::I  O:::::O     O:::::O    SSS::::::::SS  
      A:::::AAAAAAAAA:::::A      N::::::N   N:::::::::::No::::o     o::::o    X:::::X:::::X           SSSSSS::::S         T:::::T         U:::::D     D:::::U   D:::::D     D:::::DI::::I  O:::::O     O:::::O       SSSSSS::::S 
     A:::::::::::::::::::::A     N::::::N    N::::::::::No::::o     o::::o   X:::::X X:::::X               S:::::S        T:::::T         U:::::D     D:::::U   D:::::D     D:::::DI::::I  O:::::O     O:::::O            S:::::S
    A:::::AAAAAAAAAAAAA:::::A    N::::::N     N:::::::::No::::o     o::::oXXX:::::X   X:::::XXX            S:::::S        T:::::T         U::::::U   U::::::U   D:::::D    D:::::D I::::I  O::::::O   O::::::O            S:::::S
   A:::::A             A:::::A   N::::::N      N::::::::No:::::ooooo:::::oX::::::X     X::::::XSSSSSSS     S:::::S      TT:::::::TT       U:::::::UUU:::::::U DDD:::::DDDDD:::::DII::::::IIO:::::::OOO:::::::OSSSSSSS     S:::::S
  A:::::A               A:::::A  N::::::N       N:::::::No:::::::::::::::oX:::::X       X:::::XS::::::SSSSSS:::::S      T:::::::::T        UU:::::::::::::UU  D:::::::::::::::DD I::::::::I OO:::::::::::::OO S::::::SSSSSS:::::S
 A:::::A                 A:::::A N::::::N        N::::::N oo:::::::::::oo X:::::X       X:::::XS:::::::::::::::SS       T:::::::::T          UU:::::::::UU    D::::::::::::DDD   I::::::::I   OO:::::::::OO   S:::::::::::::::SS 
AAAAAAA                   AAAAAAANNNNNNNN         NNNNNNN   ooooooooooo   XXXXXXX       XXXXXXX SSSSSSSSSSSSSSS         TTTTTTTTTTT            UUUUUUUUU      DDDDDDDDDDDDD      IIIIIIIIII     OOOOOOOOO      SSSSSSSSSSSSSSS     

                                                 --------------------------------->     FOR ASSISTANCE,SCRIPTS AND MORE JOIN OUR DISCORD (https://discord.gg/gbJ5SyBJBv) <---------------------------------                                                                                                                                                                                                                                    
--]]
Config = {}
Config.Debug = false -- Enable debug logs
Config.Framework = 'qbx' -- 'esx', 'qb', 'qbx'
Config.Language = 'en' -- 'en'
Config.Target = 'ox'  -- 'ox', 'qb'

Config.MinimumWashAmount = 1000 -- Minimum amount of black money that can be washed
Config.WashingFeePercentage = 10 -- Percentage of money taken as fee (10%)
Config.CollectionTimeWindow = 45 -- Time in seconds the player has to collect the clean money
Config.CardLossChance = 50 -- Percentage chance (0-100) that the laundry card will be destroyed after use
Config.RequiredItem = 'laundry_card' -- Item needed to use the washing machine

Config.UISystem = {
    Notify = 'ox',        -- 'ox'
    ProgressBar = 'ox',   -- 'ox'
    AlertDialog = 'ox',   -- 'ox'
    InputDialog = 'ox',   -- 'ox'
    TextUI = 'ox',
    icon  = 'fa-solid fa-spray-can-sparkles'
}
Config.MachineProps = {
    idle = 'bkr_prop_prtmachine_dryer', -- Default washing machine prop
    inserted = 'bkr_prop_prtmachine_dryer_op', -- Prop when card is inserted
    spinning = 'bkr_prop_prtmachine_dryer_spin' -- Prop when machine is washing
}
Config.MachineLocations = {
    {
        coords = vector3(456.2181, -1317.8198, 29.3128),
        heading = 139.3531,
        label = 'Moneywash',
        washingTime = 40, -- Washing Time
        cooldown = 40,    -- Machine Cooldown 
        blip = {
            enabled = true,
            sprite = 500,  
            color = 62,     
            scale = 0.8,   
            display = 4,   
            shortRange = true 
        }
    },
    {
        coords = vector3(705.9923, -961.1241, 30.3953),
        heading = 95.0856,
        label = 'Moneywash',
        washingTime = 60, -- Washing Time
        cooldown = 60,    -- Machine Cooldown 
        blip = {
            enabled = true,
            sprite = 500,  
            color = 62,     
            scale = 0.8,   
            display = 4,   
            shortRange = true 
        }
    },
    {
        coords = vector3(3540.5610, 3653.5337, 33.8887),
        heading = 173.6375,
        label = 'Moneywash',
        washingTime = 30, -- Washing Time
        cooldown = 30,    -- Machine Cooldown 
        blip = {
            enabled = true,
            sprite = 500,  
            color = 62,     
            scale = 0.8,   
            display = 4,   
            shortRange = true 
        }
    }
}