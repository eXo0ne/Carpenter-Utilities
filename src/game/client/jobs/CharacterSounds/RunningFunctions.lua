return {
    OnStep = function(currentStep, character, raycastParams)
        local foot: BasePart = character:FindFirstChild(currentStep.."Foot")--:Clone()
        -- foot:ClearAllChildren()
        -- foot.Anchored = true
        -- foot.Parent = workspace
        -- local highlight = Instance.new("Highlight", foot)
        -- task.delay(0.25, function()
        --     foot:Destroy()
        -- end)

    end,

    Grass = function(currentStep, character)
        local foot: BasePart = character:FindFirstChild(currentStep.."Foot")
        
        local grassParticles = workspace.Grass.Grass:Clone()
        grassParticles.Parent = foot

        for _, emitter in grassParticles:GetChildren() do
            emitter:Emit(15)
        end

        task.delay(1, grassParticles.Destroy, grassParticles)
    end
}