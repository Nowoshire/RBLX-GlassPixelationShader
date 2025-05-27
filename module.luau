-- Services --
local RunService = game:GetService("RunService")

-- Constants --
local SHADERPART	= script.PixelShaderPart
local PARTSCALEMESH	= SHADERPART.Mesh
local CURRENTCAMERA	= workspace.CurrentCamera
local CF_ROTOFFSET	= CFrame.Angles(0.0000006, 0.0000006, 0.0000006) -- This value has been carefully tweaked, don't change unless you know what you're doing.
local DEFAULTOFFSET	= Vector3.new(0.3, 0.3, -0.101)
local RENDERPRIORITY= Enum.RenderPriority.Camera.Value + 1

-- Other variables --
local reparentRoutine: thread?

local function updateShaderPart()
	SHADERPART.CFrame = CURRENTCAMERA.CFrame * CF_ROTOFFSET
end

-- Module --
local pixelate = {}
local internalProps = {}
internalProps.Active = false -- Indicates whether the shader is currently enabled.
internalProps.StrengthX = 40 -- Indicates the current X pixelation strength.
internalProps.StrengthY = 40 -- Indicates the current Y pixelation strength.
internalProps.Offset = Vector3.new(0.3, 0.3, -0.101) -- Indicates the current glass shader part offset relative to the camera.
internalProps.Transparency = 1 -- Indicates the current glass shader part transparency.

--[[
Sets whether the shader effect is enabled or disabled.
]]
function pixelate.SetEnabled(enabled: boolean?)
	enabled = enabled == true -- Force convert to boolean
	
	if enabled == internalProps.Active then
		return
	end
	
	internalProps.Active = enabled
	
	if enabled then
		RunService:BindToRenderStep("UpdatePixelationShader", RENDERPRIORITY, updateShaderPart)
	else
		RunService:UnbindFromRenderStep("UpdatePixelationShader")
	end
	
	-- Prevent simultaneous parenting conflict
	if reparentRoutine then
		return
	end
	
	reparentRoutine = task.defer(function()
		SHADERPART.Parent = if internalProps.Active then CURRENTCAMERA else script
		reparentRoutine = nil
	end)
end

--[[
Sets the strength of the pixelation effect.

<strong><code>strengthX</code></strong>: Determines the strength of the effect across the <em>X</em> axis.
<strong>Default Value:</strong> 40

<strong><code>strengthY</code></strong>: Determines the strength of the effect across the <em>Y</em> axis.
<strong>Default Value:</strong> 40
]]
function pixelate.SetStrength(strengthX: number?, strengthY: number?)
	assert(strengthX == nil or type(strengthX) == "number", `argument #1 'strengthX' expects a number when defined, got {type(strengthX)} instead`)
	assert(strengthY == nil or type(strengthY) == "number", `argument #2 'strengthY' expects a number when defined, got {type(strengthY)} instead`)
	
	strengthX = strengthX or 40
	strengthY = strengthY or 40
	
	internalProps.StrengthX, internalProps.StrengthY = strengthX, strengthY
	
	PARTSCALEMESH.Scale = Vector3.new(strengthX, strengthY, 0)
end

--[[
Sets the offset of the glass pixel overlay part relative to the camera.
NOTE: Changing the offset may result in undesirable effects such as 'shivering' if not tuned carefully.

<strong><code>offset</code></strong>: Determines the offset of the glass shader part from the camera.
<strong>Default Value:</strong> Vector3 [0.3, 0.3, -0.101]
]]
function pixelate.SetOffset(offset: Vector3?)
	assert(offset == nil or typeof(offset) == "Vector3", `argument #1 'offset' expects a Vector3 when defined, got {typeof(offset)} instead.`)
	
	offset = offset or DEFAULTOFFSET
	
	internalProps.Offset = offset
	PARTSCALEMESH.Offset = offset
end

--[[
Sets the Transparency of the glass pixel overlay part.
Values above 1 result produce distortion that may be useful for a 'nausea' effect.

<strong><code>transparency</code></strong>: Determines the transparency of the glass shader part.
<strong>Default Value:</strong> 1
]]
function pixelate.SetTransparency(transparency: number?)
	assert(transparency == nil or type(transparency) == "number", `argument #1 'transparency' expects a number when defined, got {type(transparency)} instead`)
	
	transparency = transparency or 1
	
	internalProps.Transparency = transparency
	SHADERPART.Transparency = transparency
end

return table.freeze(setmetatable(pixelate, {
	__index = internalProps
})) :: typeof(table.freeze(pixelate)) & {
	read Active: boolean,
	read StrengthX: number,
	read StrengthY: number,
	read Offset: Vector3,
	read Transparency: number
}
