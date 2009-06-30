{application, fault_cron,
    [{description, "The fault tolerant cron server."},
     {vsn, "1.0"},
     {modules, [ft_cron_app, ft_cron_sup, ft_cron_server]},
     {registered, [ft_cron_sup, ft_cron_server]},
     {applications, [kernel,stdlib]},
  	 {mod, {ft_cron_app, []}}
    ]}.