use Module::Build;

Module::Build -> new(
    module_name => 'interface',
    license => 'perl',
    requires => {
        Filter::Simple => 0,
    },
) -> create_build_script;
