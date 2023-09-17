function dolphyn_viz(run_dir)
    
    fun_dir = @__DIR__
    
    py"""
    def run_viz(fun_dir, run_dir):
        import sys
        sys.path.append(fun_dir)
        import data_viz_main
        
        import pandas as pd

        data_viz_main.run_data_viz_single_run(run_dir)

        return None
    """

    py"run_viz"(fun_dir, run_dir)

end