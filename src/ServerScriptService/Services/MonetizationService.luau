--!strict
-- Single entry point for Game Passes and Developer Products.
-- With MonetizationConfig.Enabled = false every query returns the free-player answer
-- and ProcessReceipt is not bound, so the rest of the game never has to check.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonetizationConfig = require(ReplicatedStorage.Shared.MonetizationConfig)

local MonetizationService = {}

type ProductHandler = (player: Player) -> boolean

local ownedPasses: { [Player]: { [string]: boolean } } = {}
local productHandlers: { [string]: ProductHandler } = {}

-- A handler returns true once the purchase has been granted.
function MonetizationService.RegisterProductHandler(name: string, handler: ProductHandler)
	productHandlers[name] = handler
end

function MonetizationService.OwnsPass(player: Player, passKey: string): boolean
	local owned = ownedPasses[player]
	return owned ~= nil and owned[passKey] == true
end

-- Extra carry weight from passes. 0 while monetization is off.
function MonetizationService.GetInventoryBonus(player: Player): number
	local bonus = 0
	for key, pass in MonetizationConfig.GamePasses do
		if pass.inventoryBonus and MonetizationService.OwnsPass(player, key) then
			bonus += pass.inventoryBonus
		end
	end
	return bonus
end

local function loadPasses(player: Player)
	local owned = {}
	ownedPasses[player] = owned
	for key, pass in MonetizationConfig.GamePasses do
		if pass.id > 0 then
			local ok, result = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
			end)
			owned[key] = ok and result == true
		end
	end
end

local function processReceipt(receipt: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	for _, product in MonetizationConfig.DeveloperProducts do
		if product.id == receipt.ProductId then
			local handler = productHandlers[product.handler]
			if handler then
				local ok, granted = pcall(handler, player)
				if ok and granted then
					return Enum.ProductPurchaseDecision.PurchaseGranted
				end
			end
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function MonetizationService.Start()
	if not MonetizationConfig.Enabled then
		return
	end
	MarketplaceService.ProcessReceipt = processReceipt
	Players.PlayerAdded:Connect(loadPasses)
	for _, player in Players:GetPlayers() do
		task.spawn(loadPasses, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		ownedPasses[player] = nil
	end)
end

return MonetizationService
