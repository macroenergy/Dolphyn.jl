function H2Storage(EP::Model, inputs::Dict, LDS::Int)

    println("Hydrogen Storage Module")

    EP = h2_storage_all(EP, inputs)
    if LDS == 1
        EP = h2_long_duration_storage(EP, inputs)
    end

    return EP
end
