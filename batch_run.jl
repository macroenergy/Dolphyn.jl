

base_dir = "/home/gridsan/larmstrong/DOLPHYN_modeling/DOLPHYN-dev/supercloud_run_all"

# Get all items in the directory
all_items = readdir(base_dir)

# Filter out only the directories
dirnames = filter(item -> isdir(joinpath(base_dir, item)), all_items)

# Print the directories
println(dirnames)

# Grab the argument that is passed in
# This is the index into fnames for this process
task_id = parse(Int,ARGS[1])
num_tasks = parse(Int,ARGS[2])

print(task_id)
print(num_tasks)

for dir in task_id+1:num_tasks:length(dirnames)
    print(string(dirnames[dir]))
    include(string(dirnames[dir])*"/Run.jl")
end