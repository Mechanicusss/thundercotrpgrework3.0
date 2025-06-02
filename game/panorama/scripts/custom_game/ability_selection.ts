interface TimerChangedEvent {
    playerID: PlayerID;
    isDuelActive: boolean;
    duration: number;
    ended: boolean;
}

interface DuelEndEvent {}

class AbilitySelectionUI {
    // Instance variables
    panel: Panel;

    // AbilitySelectionUI constructor
    constructor(panel: Panel) {
        const _this = this
        this.panel = panel;

        this.container = this.panel.FindChild("AbilitySelection")
        
        this.panelContainer = undefined;

        this.heroes = [
            "chicken",
            "timmy",
            "muerta",
            "timbersaw",
            "gun_joe",
            "windranger",
            "alchemist",          
            "ancient_apparition", 
            "antimage",           
            "axe",                
            "bane",               
            "beastmaster",        
            "bloodseeker",        
            "chen",               
            "crystal_maiden",     
            "dark_seer",          
            "dazzle",             
            "dragon_knight",      
            "doom_bringer",     
            "doom",  
            "drow_ranger",        
            "earthshaker",        
            "enchantress",        
            "enigma",             
            "faceless_void",      
            "furion",             
            "juggernaut",         
            "kunkka",             
            "leshrac",            
            "lich",               
            "life_stealer",       
            "lina",               
            "lion",               
            "mirana",             
            "morphling",          
            "necrolyte",          
            "nevermore",          
            "night_stalker",      
            "omniknight",         
            "puck",               
            "pudge",              
            "pugna",              
            "rattletrap",         
            "razor",              
            "riki",               
            "sand_king",          
            "shadow_shaman",      
            "slardar",            
            "sniper",             
            "spectre",            
            "storm_spirit",       
            "sven",               
            "tidehunter",         
            "tinker",             
            "tiny",               
            "vengefulspirit",     
            "venomancer",         
            "viper",              
            "weaver",             
            "windrunner",         
            "witch_doctor",       
            "zuus",               
            "broodmother",        
            "skeleton_king",      
            "queenofpain",        
            "huskar",             
            "jakiro",             
            "batrider",           
            "warlock",            
            "death_prophet",      
            "ursa",               
            "bounty_hunter",      
            "silencer",           
            "spirit_breaker",     
            "invoker",            
            "clinkz",             
            "obsidian_destroyer", 
            "obsidian",
            "shadow_demon",       
            "lycan",              
            "lone_druid",         
            "brewmaster",         
            "phantom_lancer",     
            "treant",             
            "ogre_magi",          
            "chaos_knight",       
            "phantom_assassin",   
            "gyrocopter",         
            "rubick",             
            "luna",               
            "wisp",               
            "disruptor",          
            "undying",            
            "templar_assassin",   
            "naga_siren",         
            "nyx_assassin",       
            "keeper_of_the_light",
            "visage",             
            "meepo",              
            "magnataur",          
            "centaur",            
            "slark",              
            "shredder",           
            "medusa",             
            "troll_warlord",      
            "tusk",               
            "bristleback",        
            "skywrath_mage",      
            "elder_titan",        
            "abaddon",            
            "earth_spirit",       
            "ember_spirit",       
            "legion_commander",   
            "phoenix",            
            "terrorblade",        
            "techies",            
            "oracle",             
            "winter_wyvern",      
            "arc_warden",         
            "abyssal_underlord",  
            "underlord",
            "monkey_king",        
            "dark_willow",        
            "pangolier",          
            "grimstroke",         
            "mars",               
            "snapfire",           
            "void_spirit",        
            "hoodwink",           
            "dawnbreaker",        
            "marci",              
            "primal_beast",  
            "stargazer",
            "zaken",
            "stegius",
            "saitama",
            "hero_akasha",
            "fenrir",
            "asan",    
            "saber",
            "gabriel",
            "tanya"
        ]

        this.storedAbilities = []
        
        // Load snippet into panel
        CustomNetTables.SubscribeNetTableListener("ability_selection_open", this.onAbilityMenuOpen);
        CustomNetTables.SubscribeNetTableListener("ability_selection_open_replace", this.onAbilityMenuReplace);
        CustomNetTables.SubscribeNetTableListener("ability_selection_swap_position", this.onAbilityMenuSwap);
        CustomNetTables.SubscribeNetTableListener("ability_selection_swap_position_replace", this.onAbilityMenuSwapReplace);

        $.Msg(panel); // Print the panel
    }

    async createHeader() {
        const _this = this 

        const old = this.container.FindChildTraverse("AbilitySelectionHeader")
        if(old != null && old.IsValid()) {
            old.RemoveAndDeleteChildren()
            await old.DeleteAsync(0)
        }

        this.headerPanel = $.CreatePanel("Panel", this.container, "AbilitySelectionHeader");
        this.header = $.CreatePanel("Label", this.headerPanel, "AbilitySelectionHeaderText")
        this.header.text = "Ability Selection"

        const ability = $.CreatePanelWithProperties("DOTAAbilityImage", this.headerPanel, "", {
            class: "ability_cancel",
            html: "true",
            selectionpos: "auto",
            hittest: "true",
            hittestchildren: "false",
            abilityname: "ability_selection_cancel",
            onmouseover: "DOTAShowAbilityTooltip('ability_selection_cancel')",
            onmouseout: "DOTAHideAbilityTooltip()"
        });

        ability.SetPanelEvent(
          "onactivate", 
          function(){
            
            _this.container.RemoveAndDeleteChildren();
          }
        )
    }

    isValidAbility(name) {
        for(let i = 0; i < this.heroes.length; i++) {
            if(name.startsWith(this.heroes[i])) {
                return true
            }
        }

        return false
    }

    canAbilityBeChanged(tArray, name) {
        for(const ability in tArray) {
            if(tArray[ability] == name) {
                return true
            }
        }

        return false
    }

    onAbilityMenuReplace = (_, _, res) => {
        if (!res) {
            return
        }

        if(res.userEntIndex != Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID())) return;
        
        this.panelContainer.RemoveAndDeleteChildren();

        for(const randomName in res.selection) {
            let ability = res.selection[randomName]
            if(this.isValidAbility(ability)) {
                const changable = this.canAbilityBeChanged(res.changableAbilities, ability)
                const fnl = new AbilitySelectionContainer(this.panelContainer, ability, res.userEntIndex, 2, res.oldAbility, changable)
            }
        }

        this.panelContainer.style.height = (700 - this.panelContainer.GetParent().FindChildTraverse("AbilitySelectionHeader").contentheight) + "px"

        return
    }

    onAbilityMenuOpen = (_, _, res) => {
        if (!res) {
            return
        }

        if(res.userEntIndex != Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID())) return;

        this.container.RemoveAndDeleteChildren();

        this.createHeader()

        this.panelContainer = $.CreatePanel("Panel", this.container, "AbilitySelectionContainer");

        this.panelContainer.RemoveAndDeleteChildren();

        for(const name in res.abilities) {
            let ability = res.abilities[name]
            if(this.isValidAbility(ability)) {
                const ab = new AbilitySelectionContainer(this.panelContainer, ability, res.userEntIndex, 1, null, true)
            }
        }

        return
    }

    //
    onAbilityMenuSwap = (_, _, res) => {
        if (!res) {
            return
        }

        if(res.userEntIndex != Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID())) return;

        this.createHeader()

        //this.container.RemoveAndDeleteChildren();

        this.panelContainer = $.CreatePanel("Panel", this.container, "AbilitySelectionContainer");

        this.panelContainer.RemoveAndDeleteChildren();

        this.storedAbilities = []

        for(const name in res.abilities) {
            let ability = res.abilities[name]
            if(this.isValidAbility(ability)) {
                const ab = new AbilitySelectionContainer(this.panelContainer, ability, res.userEntIndex, 4, null, true)
                this.storedAbilities.push(ability)
            }
        }

        

        return
    }

    onAbilityMenuSwapReplace = (_, _, res) => {
        if (!res) {
            return
        }

        if(res.userEntIndex != Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID())) return;

        this.createHeader()

        //this.container.RemoveAndDeleteChildren();

        this.panelContainer = $.CreatePanel("Panel", this.container, "AbilitySelectionContainer");

        this.panelContainer.RemoveAndDeleteChildren();

        for(const name of this.storedAbilities) {
            let ability = name
            if(this.isValidAbility(ability)) {
                const ab = new AbilitySelectionContainer(this.panelContainer, ability, res.userEntIndex, 5, res.oldAbility, true)
            }
        }

        return
    }
}

let ui = new AbilitySelectionUI($.GetContextPanel());