# Rylan UniFi Case Study - Repository Structure

## Generated: 2025-11-30 19:05:59
Folder PATH listing for volume NVMe_Storage_02
Volume serial number is 2C6D-EA6F
F:.
|   .gitignore
|   .pre-commit-config.yaml
|   LICENSE
|   pyproject.toml
|   README.md
|   repo_structure.md
|   requirements-unifi.txt
|   requirements.txt
|   ROADMAP.md
|   
+---.github
|   \---workflows
|           ci-validate.yaml
|           validate.yml
|           
+---.pytest_cache
|   |   .gitignore
|   |   CACHEDIR.TAG
|   |   README.md
|   |   
|   \---v
|       \---cache
|               lastfailed
|               nodeids
|               stepwise
|               
+---.venv
|   |   pyvenv.cfg
|   |   
|   +---Include
|   +---Lib
|   |   \---site-packages
|   |       |   distutils-precedence.pth
|   |       |   typing_extensions.py
|   |       |   __editable__.rylan_unifi_case_study-0.1.0.pth
|   |       |   
|   |       +---annotated_types
|   |       |   |   py.typed
|   |       |   |   test_cases.py
|   |       |   |   __init__.py
|   |       |   |   
|   |       |   \---__pycache__
|   |       |           test_cases.cpython-312.pyc
|   |       |           __init__.cpython-312.pyc
|   |       |           
|   |       +---annotated_types-0.7.0.dist-info
|   |       |   |   INSTALLER
|   |       |   |   METADATA
|   |       |   |   RECORD
|   |       |   |   WHEEL
|   |       |   |   
|   |       |   \---licenses
|   |       |           LICENSE
|   |       |           
|   |       +---certifi
|   |       |   |   cacert.pem
|   |       |   |   core.py
|   |       |   |   py.typed
|   |       |   |   __init__.py
|   |       |   |   __main__.py
|   |       |   |   
|   |       |   \---__pycache__
|   |       |           core.cpython-312.pyc
|   |       |           __init__.cpython-312.pyc
|   |       |           __main__.cpython-312.pyc
|   |       |           
|   |       +---certifi-2025.11.12.dist-info
|   |       |   |   INSTALLER
|   |       |   |   METADATA
|   |       |   |   RECORD
|   |       |   |   top_level.txt
|   |       |   |   WHEEL
|   |       |   |   
|   |       |   \---licenses
|   |       |           LICENSE
|   |       |           
|   |       +---charset_normalizer
|   |       |   |   api.py
|   |       |   |   cd.py
|   |       |   |   constant.py
|   |       |   |   legacy.py
|   |       |   |   md.cp312-win_amd64.pyd
|   |       |   |   md.py
|   |       |   |   md__mypyc.cp312-win_amd64.pyd
|   |       |   |   models.py
|   |       |   |   py.typed
|   |       |   |   utils.py
|   |       |   |   version.py
|   |       |   |   __init__.py
|   |       |   |   __main__.py
|   |       |   |   
|   |       |   +---cli
|   |       |   |   |   __init__.py
|   |       |   |   |   __main__.py
|   |       |   |   |   
|   |       |   |   \---__pycache__
|   |       |   |           __init__.cpython-312.pyc
|   |       |   |           __main__.cpython-312.pyc
|   |       |   |           
|   |       |   \---__pycache__
|   |       |           api.cpython-312.pyc
|   |       |           cd.cpython-312.pyc
|   |       |           constant.cpython-312.pyc
|   |       |           legacy.cpython-312.pyc
|   |       |           md.cpython-312.pyc
|   |       |           models.cpython-312.pyc
|   |       |           utils.cpython-312.pyc
|   |       |           version.cpython-312.pyc
|   |       |           __init__.cpython-312.pyc
|   |       |           __main__.cpython-312.pyc
|   |       |           
|   |       +---charset_normalizer-3.4.4.dist-info
|   |       |   |   entry_points.txt
|   |       |   |   INSTALLER
|   |       |   |   METADATA
|   |       |   |   RECORD
|   |       |   |   top_level.txt
|   |       |   |   WHEEL
|   |       |   |   
|   |       |   \---licenses
|   |       |           LICENSE
|   |       |           
|   |       +---deepdiff
|   |       |   |   anyset.py
|   |       |   |   base.py
|   |       |   |   commands.py
|   |       |   |   deephash.py
|   |       |   |   delta.py
|   |       |   |   diff.py
|   |       |   |   distance.py
|   |       |   |   helper.py
|   |       |   |   lfucache.py
|   |       |   |   model.py
|   |       |   |   operator.py
|   |       |   |   path.py
|   |       |   |   search.py
|   |       |   |   serialization.py
|   |       |   |   __init__.py
|   |       |   |   
|   |       |   \---__pycache__
|   |       |           anyset.cpython-312.pyc
|   |       |           base.cpython-312.pyc
|   |       |           commands.cpython-312.pyc
|   |       |           deephash.cpython-312.pyc
|   |       |           delta.cpython-312.pyc
|   |       |           diff.cpython-312.pyc
|   |       |           distance.cpython-312.pyc
|   |       |           helper.cpython-312.pyc
|   |       |           lfucache.cpython-312.pyc
|   |       |           model.cpython-312.pyc
|   |       |           operator.cpython-312.pyc
|   |       |           path.cpython-312.pyc
|   |       |           search.cpython-312.pyc
|   |       |           serialization.cpython-312.pyc
|   |       |           __init__.cpython-312.pyc
|   |       |           
|   |       +---deepdiff-6.7.1.dist-info
|   |       |       AUTHORS.md
|   |       |       entry_points.txt
|   |       |       INSTALLER
|   |       |       LICENSE
|   |       |       METADATA
|   |       |       RECORD
|   |       |       top_level.txt
|   |       |       WHEEL
|   |       |       zip-safe
|   |       |       
|   |       +---idna
|   |       |   |   codec.py
|   |       |   |   compat.py
|   |       |   |   core.py
|   |       |   |   idnadata.py
|   |       |   |   intranges.py
|   |       |   |   package_data.py
|   |       |   |   py.typed
|   |       |   |   uts46data.py
|   |       |   |   __init__.py
|   |       |   |   
|   |       |   \---__pycache__
|   |       |           codec.cpython-312.pyc
|   |       |           compat.cpython-312.pyc
|   |       |           core.cpython-312.pyc
|   |       |           idnadata.cpython-312.pyc
|   |       |           intranges.cpython-312.pyc
|   |       |           package_data.cpython-312.pyc
|   |       |           uts46data.cpython-312.pyc
|   |       |           __init__.cpython-312.pyc
|   |       |           
|   |       +---idna-3.11.dist-info
|   |       |   |   INSTALLER
|   |       |   |   METADATA
|   |       |   |   RECORD
|   |       |   |   WHEEL
|   |       |   |   
|   |       |   \---licenses
|   |       |           LICENSE.md
|   |       |           
|   |       +---ordered_set
|   |       |   |   py.typed
|   |       |   |   __init__.py
|   |       |   |   
|   |       |   \---__pycache__
|   |       |           __init__.cpython-312.pyc
|   |       |           
|   |       +---ordered_set-4.1.0.dist-info
|   |       |       INSTALLER
|   |       |       METADATA
|   |       |       RECORD
|   |       |       WHEEL
|   |       |       
|   |       +---pip
|   |       |   |   py.typed
|   |       |   |   __init__.py
|   |       |   |   __main__.py
|   |       |   |   __pip-runner__.py
|   |       |   |   
|   |       |   +---_internal
|   |       |   |   |   build_env.py
|   |       |   |   |   cache.py
|   |       |   |   |   configuration.py
|   |       |   |   |   exceptions.py
|   |       |   |   |   main.py
|   |       |   |   |   pyproject.py
|   |       |   |   |   self_outdated_check.py
|   |       |   |   |   wheel_builder.py
|   |       |   |   |   __init__.py
|   |       |   |   |   
|   |       |   |   +---cli
|   |       |   |   |   |   autocompletion.py
|   |       |   |   |   |   base_command.py
|   |       |   |   |   |   cmdoptions.py
|   |       |   |   |   |   command_context.py
|   |       |   |   |   |   index_command.py
|   |       |   |   |   |   main.py
|   |       |   |   |   |   main_parser.py
|   |       |   |   |   |   parser.py
|   |       |   |   |   |   progress_bars.py
|   |       |   |   |   |   req_command.py
|   |       |   |   |   |   spinners.py
|   |       |   |   |   |   status_codes.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           autocompletion.cpython-312.pyc
|   |       |   |   |           base_command.cpython-312.pyc
|   |       |   |   |           cmdoptions.cpython-312.pyc
|   |       |   |   |           command_context.cpython-312.pyc
|   |       |   |   |           index_command.cpython-312.pyc
|   |       |   |   |           main.cpython-312.pyc
|   |       |   |   |           main_parser.cpython-312.pyc
|   |       |   |   |           parser.cpython-312.pyc
|   |       |   |   |           progress_bars.cpython-312.pyc
|   |       |   |   |           req_command.cpython-312.pyc
|   |       |   |   |           spinners.cpython-312.pyc
|   |       |   |   |           status_codes.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---commands
|   |       |   |   |   |   cache.py
|   |       |   |   |   |   check.py
|   |       |   |   |   |   completion.py
|   |       |   |   |   |   configuration.py
|   |       |   |   |   |   debug.py
|   |       |   |   |   |   download.py
|   |       |   |   |   |   freeze.py
|   |       |   |   |   |   hash.py
|   |       |   |   |   |   help.py
|   |       |   |   |   |   index.py
|   |       |   |   |   |   inspect.py
|   |       |   |   |   |   install.py
|   |       |   |   |   |   list.py
|   |       |   |   |   |   lock.py
|   |       |   |   |   |   search.py
|   |       |   |   |   |   show.py
|   |       |   |   |   |   uninstall.py
|   |       |   |   |   |   wheel.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           cache.cpython-312.pyc
|   |       |   |   |           check.cpython-312.pyc
|   |       |   |   |           completion.cpython-312.pyc
|   |       |   |   |           configuration.cpython-312.pyc
|   |       |   |   |           debug.cpython-312.pyc
|   |       |   |   |           download.cpython-312.pyc
|   |       |   |   |           freeze.cpython-312.pyc
|   |       |   |   |           hash.cpython-312.pyc
|   |       |   |   |           help.cpython-312.pyc
|   |       |   |   |           index.cpython-312.pyc
|   |       |   |   |           inspect.cpython-312.pyc
|   |       |   |   |           install.cpython-312.pyc
|   |       |   |   |           list.cpython-312.pyc
|   |       |   |   |           lock.cpython-312.pyc
|   |       |   |   |           search.cpython-312.pyc
|   |       |   |   |           show.cpython-312.pyc
|   |       |   |   |           uninstall.cpython-312.pyc
|   |       |   |   |           wheel.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---distributions
|   |       |   |   |   |   base.py
|   |       |   |   |   |   installed.py
|   |       |   |   |   |   sdist.py
|   |       |   |   |   |   wheel.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           base.cpython-312.pyc
|   |       |   |   |           installed.cpython-312.pyc
|   |       |   |   |           sdist.cpython-312.pyc
|   |       |   |   |           wheel.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---index
|   |       |   |   |   |   collector.py
|   |       |   |   |   |   package_finder.py
|   |       |   |   |   |   sources.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           collector.cpython-312.pyc
|   |       |   |   |           package_finder.cpython-312.pyc
|   |       |   |   |           sources.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---locations
|   |       |   |   |   |   base.py
|   |       |   |   |   |   _distutils.py
|   |       |   |   |   |   _sysconfig.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           base.cpython-312.pyc
|   |       |   |   |           _distutils.cpython-312.pyc
|   |       |   |   |           _sysconfig.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---metadata
|   |       |   |   |   |   base.py
|   |       |   |   |   |   pkg_resources.py
|   |       |   |   |   |   _json.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   +---importlib
|   |       |   |   |   |   |   _compat.py
|   |       |   |   |   |   |   _dists.py
|   |       |   |   |   |   |   _envs.py
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           _compat.cpython-312.pyc
|   |       |   |   |   |           _dists.cpython-312.pyc
|   |       |   |   |   |           _envs.cpython-312.pyc
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   \---__pycache__
|   |       |   |   |           base.cpython-312.pyc
|   |       |   |   |           pkg_resources.cpython-312.pyc
|   |       |   |   |           _json.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---models
|   |       |   |   |   |   candidate.py
|   |       |   |   |   |   direct_url.py
|   |       |   |   |   |   format_control.py
|   |       |   |   |   |   index.py
|   |       |   |   |   |   installation_report.py
|   |       |   |   |   |   link.py
|   |       |   |   |   |   pylock.py
|   |       |   |   |   |   scheme.py
|   |       |   |   |   |   search_scope.py
|   |       |   |   |   |   selection_prefs.py
|   |       |   |   |   |   target_python.py
|   |       |   |   |   |   wheel.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           candidate.cpython-312.pyc
|   |       |   |   |           direct_url.cpython-312.pyc
|   |       |   |   |           format_control.cpython-312.pyc
|   |       |   |   |           index.cpython-312.pyc
|   |       |   |   |           installation_report.cpython-312.pyc
|   |       |   |   |           link.cpython-312.pyc
|   |       |   |   |           pylock.cpython-312.pyc
|   |       |   |   |           scheme.cpython-312.pyc
|   |       |   |   |           search_scope.cpython-312.pyc
|   |       |   |   |           selection_prefs.cpython-312.pyc
|   |       |   |   |           target_python.cpython-312.pyc
|   |       |   |   |           wheel.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---network
|   |       |   |   |   |   auth.py
|   |       |   |   |   |   cache.py
|   |       |   |   |   |   download.py
|   |       |   |   |   |   lazy_wheel.py
|   |       |   |   |   |   session.py
|   |       |   |   |   |   utils.py
|   |       |   |   |   |   xmlrpc.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           auth.cpython-312.pyc
|   |       |   |   |           cache.cpython-312.pyc
|   |       |   |   |           download.cpython-312.pyc
|   |       |   |   |           lazy_wheel.cpython-312.pyc
|   |       |   |   |           session.cpython-312.pyc
|   |       |   |   |           utils.cpython-312.pyc
|   |       |   |   |           xmlrpc.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---operations
|   |       |   |   |   |   check.py
|   |       |   |   |   |   freeze.py
|   |       |   |   |   |   prepare.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   +---build
|   |       |   |   |   |   |   build_tracker.py
|   |       |   |   |   |   |   metadata.py
|   |       |   |   |   |   |   metadata_editable.py
|   |       |   |   |   |   |   wheel.py
|   |       |   |   |   |   |   wheel_editable.py
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           build_tracker.cpython-312.pyc
|   |       |   |   |   |           metadata.cpython-312.pyc
|   |       |   |   |   |           metadata_editable.cpython-312.pyc
|   |       |   |   |   |           wheel.cpython-312.pyc
|   |       |   |   |   |           wheel_editable.cpython-312.pyc
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   +---install
|   |       |   |   |   |   |   wheel.py
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           wheel.cpython-312.pyc
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   \---__pycache__
|   |       |   |   |           check.cpython-312.pyc
|   |       |   |   |           freeze.cpython-312.pyc
|   |       |   |   |           prepare.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---req
|   |       |   |   |   |   constructors.py
|   |       |   |   |   |   req_dependency_group.py
|   |       |   |   |   |   req_file.py
|   |       |   |   |   |   req_install.py
|   |       |   |   |   |   req_set.py
|   |       |   |   |   |   req_uninstall.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           constructors.cpython-312.pyc
|   |       |   |   |           req_dependency_group.cpython-312.pyc
|   |       |   |   |           req_file.cpython-312.pyc
|   |       |   |   |           req_install.cpython-312.pyc
|   |       |   |   |           req_set.cpython-312.pyc
|   |       |   |   |           req_uninstall.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---resolution
|   |       |   |   |   |   base.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   +---legacy
|   |       |   |   |   |   |   resolver.py
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           resolver.cpython-312.pyc
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   +---resolvelib
|   |       |   |   |   |   |   base.py
|   |       |   |   |   |   |   candidates.py
|   |       |   |   |   |   |   factory.py
|   |       |   |   |   |   |   found_candidates.py
|   |       |   |   |   |   |   provider.py
|   |       |   |   |   |   |   reporter.py
|   |       |   |   |   |   |   requirements.py
|   |       |   |   |   |   |   resolver.py
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           base.cpython-312.pyc
|   |       |   |   |   |           candidates.cpython-312.pyc
|   |       |   |   |   |           factory.cpython-312.pyc
|   |       |   |   |   |           found_candidates.cpython-312.pyc
|   |       |   |   |   |           provider.cpython-312.pyc
|   |       |   |   |   |           reporter.cpython-312.pyc
|   |       |   |   |   |           requirements.cpython-312.pyc
|   |       |   |   |   |           resolver.cpython-312.pyc
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   \---__pycache__
|   |       |   |   |           base.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---utils
|   |       |   |   |   |   appdirs.py
|   |       |   |   |   |   compat.py
|   |       |   |   |   |   compatibility_tags.py
|   |       |   |   |   |   datetime.py
|   |       |   |   |   |   deprecation.py
|   |       |   |   |   |   direct_url_helpers.py
|   |       |   |   |   |   egg_link.py
|   |       |   |   |   |   entrypoints.py
|   |       |   |   |   |   filesystem.py
|   |       |   |   |   |   filetypes.py
|   |       |   |   |   |   glibc.py
|   |       |   |   |   |   hashes.py
|   |       |   |   |   |   logging.py
|   |       |   |   |   |   misc.py
|   |       |   |   |   |   packaging.py
|   |       |   |   |   |   retry.py
|   |       |   |   |   |   subprocess.py
|   |       |   |   |   |   temp_dir.py
|   |       |   |   |   |   unpacking.py
|   |       |   |   |   |   urls.py
|   |       |   |   |   |   virtualenv.py
|   |       |   |   |   |   wheel.py
|   |       |   |   |   |   _jaraco_text.py
|   |       |   |   |   |   _log.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           appdirs.cpython-312.pyc
|   |       |   |   |           compat.cpython-312.pyc
|   |       |   |   |           compatibility_tags.cpython-312.pyc
|   |       |   |   |           datetime.cpython-312.pyc
|   |       |   |   |           deprecation.cpython-312.pyc
|   |       |   |   |           direct_url_helpers.cpython-312.pyc
|   |       |   |   |           egg_link.cpython-312.pyc
|   |       |   |   |           entrypoints.cpython-312.pyc
|   |       |   |   |           filesystem.cpython-312.pyc
|   |       |   |   |           filetypes.cpython-312.pyc
|   |       |   |   |           glibc.cpython-312.pyc
|   |       |   |   |           hashes.cpython-312.pyc
|   |       |   |   |           logging.cpython-312.pyc
|   |       |   |   |           misc.cpython-312.pyc
|   |       |   |   |           packaging.cpython-312.pyc
|   |       |   |   |           retry.cpython-312.pyc
|   |       |   |   |           subprocess.cpython-312.pyc
|   |       |   |   |           temp_dir.cpython-312.pyc
|   |       |   |   |           unpacking.cpython-312.pyc
|   |       |   |   |           urls.cpython-312.pyc
|   |       |   |   |           virtualenv.cpython-312.pyc
|   |       |   |   |           wheel.cpython-312.pyc
|   |       |   |   |           _jaraco_text.cpython-312.pyc
|   |       |   |   |           _log.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---vcs
|   |       |   |   |   |   bazaar.py
|   |       |   |   |   |   git.py
|   |       |   |   |   |   mercurial.py
|   |       |   |   |   |   subversion.py
|   |       |   |   |   |   versioncontrol.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           bazaar.cpython-312.pyc
|   |       |   |   |           git.cpython-312.pyc
|   |       |   |   |           mercurial.cpython-312.pyc
|   |       |   |   |           subversion.cpython-312.pyc
|   |       |   |   |           versioncontrol.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   \---__pycache__
|   |       |   |           build_env.cpython-312.pyc
|   |       |   |           cache.cpython-312.pyc
|   |       |   |           configuration.cpython-312.pyc
|   |       |   |           exceptions.cpython-312.pyc
|   |       |   |           main.cpython-312.pyc
|   |       |   |           pyproject.cpython-312.pyc
|   |       |   |           self_outdated_check.cpython-312.pyc
|   |       |   |           wheel_builder.cpython-312.pyc
|   |       |   |           __init__.cpython-312.pyc
|   |       |   |           
|   |       |   +---_vendor
|   |       |   |   |   README.rst
|   |       |   |   |   vendor.txt
|   |       |   |   |   __init__.py
|   |       |   |   |   
|   |       |   |   +---cachecontrol
|   |       |   |   |   |   adapter.py
|   |       |   |   |   |   cache.py
|   |       |   |   |   |   controller.py
|   |       |   |   |   |   filewrapper.py
|   |       |   |   |   |   heuristics.py
|   |       |   |   |   |   LICENSE.txt
|   |       |   |   |   |   py.typed
|   |       |   |   |   |   serialize.py
|   |       |   |   |   |   wrapper.py
|   |       |   |   |   |   _cmd.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   +---caches
|   |       |   |   |   |   |   file_cache.py
|   |       |   |   |   |   |   redis_cache.py
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           file_cache.cpython-312.pyc
|   |       |   |   |   |           redis_cache.cpython-312.pyc
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   \---__pycache__
|   |       |   |   |           adapter.cpython-312.pyc
|   |       |   |   |           cache.cpython-312.pyc
|   |       |   |   |           controller.cpython-312.pyc
|   |       |   |   |           filewrapper.cpython-312.pyc
|   |       |   |   |           heuristics.cpython-312.pyc
|   |       |   |   |           serialize.cpython-312.pyc
|   |       |   |   |           wrapper.cpython-312.pyc
|   |       |   |   |           _cmd.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---certifi
|   |       |   |   |   |   cacert.pem
|   |       |   |   |   |   core.py
|   |       |   |   |   |   LICENSE
|   |       |   |   |   |   py.typed
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   __main__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           core.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           __main__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---dependency_groups
|   |       |   |   |   |   LICENSE.txt
|   |       |   |   |   |   py.typed
|   |       |   |   |   |   _implementation.py
|   |       |   |   |   |   _lint_dependency_groups.py
|   |       |   |   |   |   _pip_wrapper.py
|   |       |   |   |   |   _toml_compat.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   __main__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           _implementation.cpython-312.pyc
|   |       |   |   |           _lint_dependency_groups.cpython-312.pyc
|   |       |   |   |           _pip_wrapper.cpython-312.pyc
|   |       |   |   |           _toml_compat.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           __main__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---distlib
|   |       |   |   |   |   compat.py
|   |       |   |   |   |   LICENSE.txt
|   |       |   |   |   |   resources.py
|   |       |   |   |   |   scripts.py
|   |       |   |   |   |   t32.exe
|   |       |   |   |   |   t64-arm.exe
|   |       |   |   |   |   t64.exe
|   |       |   |   |   |   util.py
|   |       |   |   |   |   w32.exe
|   |       |   |   |   |   w64-arm.exe
|   |       |   |   |   |   w64.exe
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           compat.cpython-312.pyc
|   |       |   |   |           resources.cpython-312.pyc
|   |       |   |   |           scripts.cpython-312.pyc
|   |       |   |   |           util.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---distro
|   |       |   |   |   |   distro.py
|   |       |   |   |   |   LICENSE
|   |       |   |   |   |   py.typed
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   __main__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           distro.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           __main__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---idna
|   |       |   |   |   |   codec.py
|   |       |   |   |   |   compat.py
|   |       |   |   |   |   core.py
|   |       |   |   |   |   idnadata.py
|   |       |   |   |   |   intranges.py
|   |       |   |   |   |   LICENSE.md
|   |       |   |   |   |   package_data.py
|   |       |   |   |   |   py.typed
|   |       |   |   |   |   uts46data.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           codec.cpython-312.pyc
|   |       |   |   |           compat.cpython-312.pyc
|   |       |   |   |           core.cpython-312.pyc
|   |       |   |   |           idnadata.cpython-312.pyc
|   |       |   |   |           intranges.cpython-312.pyc
|   |       |   |   |           package_data.cpython-312.pyc
|   |       |   |   |           uts46data.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---msgpack
|   |       |   |   |   |   COPYING
|   |       |   |   |   |   exceptions.py
|   |       |   |   |   |   ext.py
|   |       |   |   |   |   fallback.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           exceptions.cpython-312.pyc
|   |       |   |   |           ext.cpython-312.pyc
|   |       |   |   |           fallback.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---packaging
|   |       |   |   |   |   LICENSE
|   |       |   |   |   |   LICENSE.APACHE
|   |       |   |   |   |   LICENSE.BSD
|   |       |   |   |   |   markers.py
|   |       |   |   |   |   metadata.py
|   |       |   |   |   |   py.typed
|   |       |   |   |   |   requirements.py
|   |       |   |   |   |   specifiers.py
|   |       |   |   |   |   tags.py
|   |       |   |   |   |   utils.py
|   |       |   |   |   |   version.py
|   |       |   |   |   |   _elffile.py
|   |       |   |   |   |   _manylinux.py
|   |       |   |   |   |   _musllinux.py
|   |       |   |   |   |   _parser.py
|   |       |   |   |   |   _structures.py
|   |       |   |   |   |   _tokenizer.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   +---licenses
|   |       |   |   |   |   |   _spdx.py
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           _spdx.cpython-312.pyc
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   \---__pycache__
|   |       |   |   |           markers.cpython-312.pyc
|   |       |   |   |           metadata.cpython-312.pyc
|   |       |   |   |           requirements.cpython-312.pyc
|   |       |   |   |           specifiers.cpython-312.pyc
|   |       |   |   |           tags.cpython-312.pyc
|   |       |   |   |           utils.cpython-312.pyc
|   |       |   |   |           version.cpython-312.pyc
|   |       |   |   |           _elffile.cpython-312.pyc
|   |       |   |   |           _manylinux.cpython-312.pyc
|   |       |   |   |           _musllinux.cpython-312.pyc
|   |       |   |   |           _parser.cpython-312.pyc
|   |       |   |   |           _structures.cpython-312.pyc
|   |       |   |   |           _tokenizer.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---pkg_resources
|   |       |   |   |   |   LICENSE
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---platformdirs
|   |       |   |   |   |   android.py
|   |       |   |   |   |   api.py
|   |       |   |   |   |   LICENSE
|   |       |   |   |   |   macos.py
|   |       |   |   |   |   py.typed
|   |       |   |   |   |   unix.py
|   |       |   |   |   |   version.py
|   |       |   |   |   |   windows.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   __main__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           android.cpython-312.pyc
|   |       |   |   |           api.cpython-312.pyc
|   |       |   |   |           macos.cpython-312.pyc
|   |       |   |   |           unix.cpython-312.pyc
|   |       |   |   |           version.cpython-312.pyc
|   |       |   |   |           windows.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           __main__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---pygments
|   |       |   |   |   |   console.py
|   |       |   |   |   |   filter.py
|   |       |   |   |   |   formatter.py
|   |       |   |   |   |   lexer.py
|   |       |   |   |   |   LICENSE
|   |       |   |   |   |   modeline.py
|   |       |   |   |   |   plugin.py
|   |       |   |   |   |   regexopt.py
|   |       |   |   |   |   scanner.py
|   |       |   |   |   |   sphinxext.py
|   |       |   |   |   |   style.py
|   |       |   |   |   |   token.py
|   |       |   |   |   |   unistring.py
|   |       |   |   |   |   util.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   __main__.py
|   |       |   |   |   |   
|   |       |   |   |   +---filters
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   +---formatters
|   |       |   |   |   |   |   _mapping.py
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           _mapping.cpython-312.pyc
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   +---lexers
|   |       |   |   |   |   |   python.py
|   |       |   |   |   |   |   _mapping.py
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           python.cpython-312.pyc
|   |       |   |   |   |           _mapping.cpython-312.pyc
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   +---styles
|   |       |   |   |   |   |   _mapping.py
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           _mapping.cpython-312.pyc
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   \---__pycache__
|   |       |   |   |           console.cpython-312.pyc
|   |       |   |   |           filter.cpython-312.pyc
|   |       |   |   |           formatter.cpython-312.pyc
|   |       |   |   |           lexer.cpython-312.pyc
|   |       |   |   |           modeline.cpython-312.pyc
|   |       |   |   |           plugin.cpython-312.pyc
|   |       |   |   |           regexopt.cpython-312.pyc
|   |       |   |   |           scanner.cpython-312.pyc
|   |       |   |   |           sphinxext.cpython-312.pyc
|   |       |   |   |           style.cpython-312.pyc
|   |       |   |   |           token.cpython-312.pyc
|   |       |   |   |           unistring.cpython-312.pyc
|   |       |   |   |           util.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           __main__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---pyproject_hooks
|   |       |   |   |   |   LICENSE
|   |       |   |   |   |   py.typed
|   |       |   |   |   |   _impl.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   +---_in_process
|   |       |   |   |   |   |   _in_process.py
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           _in_process.cpython-312.pyc
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   \---__pycache__
|   |       |   |   |           _impl.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---requests
|   |       |   |   |   |   adapters.py
|   |       |   |   |   |   api.py
|   |       |   |   |   |   auth.py
|   |       |   |   |   |   certs.py
|   |       |   |   |   |   compat.py
|   |       |   |   |   |   cookies.py
|   |       |   |   |   |   exceptions.py
|   |       |   |   |   |   help.py
|   |       |   |   |   |   hooks.py
|   |       |   |   |   |   LICENSE
|   |       |   |   |   |   models.py
|   |       |   |   |   |   packages.py
|   |       |   |   |   |   sessions.py
|   |       |   |   |   |   status_codes.py
|   |       |   |   |   |   structures.py
|   |       |   |   |   |   utils.py
|   |       |   |   |   |   _internal_utils.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   __version__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           adapters.cpython-312.pyc
|   |       |   |   |           api.cpython-312.pyc
|   |       |   |   |           auth.cpython-312.pyc
|   |       |   |   |           certs.cpython-312.pyc
|   |       |   |   |           compat.cpython-312.pyc
|   |       |   |   |           cookies.cpython-312.pyc
|   |       |   |   |           exceptions.cpython-312.pyc
|   |       |   |   |           help.cpython-312.pyc
|   |       |   |   |           hooks.cpython-312.pyc
|   |       |   |   |           models.cpython-312.pyc
|   |       |   |   |           packages.cpython-312.pyc
|   |       |   |   |           sessions.cpython-312.pyc
|   |       |   |   |           status_codes.cpython-312.pyc
|   |       |   |   |           structures.cpython-312.pyc
|   |       |   |   |           utils.cpython-312.pyc
|   |       |   |   |           _internal_utils.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           __version__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---resolvelib
|   |       |   |   |   |   LICENSE
|   |       |   |   |   |   providers.py
|   |       |   |   |   |   py.typed
|   |       |   |   |   |   reporters.py
|   |       |   |   |   |   structs.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   +---resolvers
|   |       |   |   |   |   |   abstract.py
|   |       |   |   |   |   |   criterion.py
|   |       |   |   |   |   |   exceptions.py
|   |       |   |   |   |   |   resolution.py
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           abstract.cpython-312.pyc
|   |       |   |   |   |           criterion.cpython-312.pyc
|   |       |   |   |   |           exceptions.cpython-312.pyc
|   |       |   |   |   |           resolution.cpython-312.pyc
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   \---__pycache__
|   |       |   |   |           providers.cpython-312.pyc
|   |       |   |   |           reporters.cpython-312.pyc
|   |       |   |   |           structs.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---rich
|   |       |   |   |   |   abc.py
|   |       |   |   |   |   align.py
|   |       |   |   |   |   ansi.py
|   |       |   |   |   |   bar.py
|   |       |   |   |   |   box.py
|   |       |   |   |   |   cells.py
|   |       |   |   |   |   color.py
|   |       |   |   |   |   color_triplet.py
|   |       |   |   |   |   columns.py
|   |       |   |   |   |   console.py
|   |       |   |   |   |   constrain.py
|   |       |   |   |   |   containers.py
|   |       |   |   |   |   control.py
|   |       |   |   |   |   default_styles.py
|   |       |   |   |   |   diagnose.py
|   |       |   |   |   |   emoji.py
|   |       |   |   |   |   errors.py
|   |       |   |   |   |   filesize.py
|   |       |   |   |   |   file_proxy.py
|   |       |   |   |   |   highlighter.py
|   |       |   |   |   |   json.py
|   |       |   |   |   |   jupyter.py
|   |       |   |   |   |   layout.py
|   |       |   |   |   |   LICENSE
|   |       |   |   |   |   live.py
|   |       |   |   |   |   live_render.py
|   |       |   |   |   |   logging.py
|   |       |   |   |   |   markup.py
|   |       |   |   |   |   measure.py
|   |       |   |   |   |   padding.py
|   |       |   |   |   |   pager.py
|   |       |   |   |   |   palette.py
|   |       |   |   |   |   panel.py
|   |       |   |   |   |   pretty.py
|   |       |   |   |   |   progress.py
|   |       |   |   |   |   progress_bar.py
|   |       |   |   |   |   prompt.py
|   |       |   |   |   |   protocol.py
|   |       |   |   |   |   py.typed
|   |       |   |   |   |   region.py
|   |       |   |   |   |   repr.py
|   |       |   |   |   |   rule.py
|   |       |   |   |   |   scope.py
|   |       |   |   |   |   screen.py
|   |       |   |   |   |   segment.py
|   |       |   |   |   |   spinner.py
|   |       |   |   |   |   status.py
|   |       |   |   |   |   style.py
|   |       |   |   |   |   styled.py
|   |       |   |   |   |   syntax.py
|   |       |   |   |   |   table.py
|   |       |   |   |   |   terminal_theme.py
|   |       |   |   |   |   text.py
|   |       |   |   |   |   theme.py
|   |       |   |   |   |   themes.py
|   |       |   |   |   |   traceback.py
|   |       |   |   |   |   tree.py
|   |       |   |   |   |   _cell_widths.py
|   |       |   |   |   |   _emoji_codes.py
|   |       |   |   |   |   _emoji_replace.py
|   |       |   |   |   |   _export_format.py
|   |       |   |   |   |   _extension.py
|   |       |   |   |   |   _fileno.py
|   |       |   |   |   |   _inspect.py
|   |       |   |   |   |   _log_render.py
|   |       |   |   |   |   _loop.py
|   |       |   |   |   |   _null_file.py
|   |       |   |   |   |   _palettes.py
|   |       |   |   |   |   _pick.py
|   |       |   |   |   |   _ratio.py
|   |       |   |   |   |   _spinners.py
|   |       |   |   |   |   _stack.py
|   |       |   |   |   |   _timer.py
|   |       |   |   |   |   _win32_console.py
|   |       |   |   |   |   _windows.py
|   |       |   |   |   |   _windows_renderer.py
|   |       |   |   |   |   _wrap.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   __main__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           abc.cpython-312.pyc
|   |       |   |   |           align.cpython-312.pyc
|   |       |   |   |           ansi.cpython-312.pyc
|   |       |   |   |           bar.cpython-312.pyc
|   |       |   |   |           box.cpython-312.pyc
|   |       |   |   |           cells.cpython-312.pyc
|   |       |   |   |           color.cpython-312.pyc
|   |       |   |   |           color_triplet.cpython-312.pyc
|   |       |   |   |           columns.cpython-312.pyc
|   |       |   |   |           console.cpython-312.pyc
|   |       |   |   |           constrain.cpython-312.pyc
|   |       |   |   |           containers.cpython-312.pyc
|   |       |   |   |           control.cpython-312.pyc
|   |       |   |   |           default_styles.cpython-312.pyc
|   |       |   |   |           diagnose.cpython-312.pyc
|   |       |   |   |           emoji.cpython-312.pyc
|   |       |   |   |           errors.cpython-312.pyc
|   |       |   |   |           filesize.cpython-312.pyc
|   |       |   |   |           file_proxy.cpython-312.pyc
|   |       |   |   |           highlighter.cpython-312.pyc
|   |       |   |   |           json.cpython-312.pyc
|   |       |   |   |           jupyter.cpython-312.pyc
|   |       |   |   |           layout.cpython-312.pyc
|   |       |   |   |           live.cpython-312.pyc
|   |       |   |   |           live_render.cpython-312.pyc
|   |       |   |   |           logging.cpython-312.pyc
|   |       |   |   |           markup.cpython-312.pyc
|   |       |   |   |           measure.cpython-312.pyc
|   |       |   |   |           padding.cpython-312.pyc
|   |       |   |   |           pager.cpython-312.pyc
|   |       |   |   |           palette.cpython-312.pyc
|   |       |   |   |           panel.cpython-312.pyc
|   |       |   |   |           pretty.cpython-312.pyc
|   |       |   |   |           progress.cpython-312.pyc
|   |       |   |   |           progress_bar.cpython-312.pyc
|   |       |   |   |           prompt.cpython-312.pyc
|   |       |   |   |           protocol.cpython-312.pyc
|   |       |   |   |           region.cpython-312.pyc
|   |       |   |   |           repr.cpython-312.pyc
|   |       |   |   |           rule.cpython-312.pyc
|   |       |   |   |           scope.cpython-312.pyc
|   |       |   |   |           screen.cpython-312.pyc
|   |       |   |   |           segment.cpython-312.pyc
|   |       |   |   |           spinner.cpython-312.pyc
|   |       |   |   |           status.cpython-312.pyc
|   |       |   |   |           style.cpython-312.pyc
|   |       |   |   |           styled.cpython-312.pyc
|   |       |   |   |           syntax.cpython-312.pyc
|   |       |   |   |           table.cpython-312.pyc
|   |       |   |   |           terminal_theme.cpython-312.pyc
|   |       |   |   |           text.cpython-312.pyc
|   |       |   |   |           theme.cpython-312.pyc
|   |       |   |   |           themes.cpython-312.pyc
|   |       |   |   |           traceback.cpython-312.pyc
|   |       |   |   |           tree.cpython-312.pyc
|   |       |   |   |           _cell_widths.cpython-312.pyc
|   |       |   |   |           _emoji_codes.cpython-312.pyc
|   |       |   |   |           _emoji_replace.cpython-312.pyc
|   |       |   |   |           _export_format.cpython-312.pyc
|   |       |   |   |           _extension.cpython-312.pyc
|   |       |   |   |           _fileno.cpython-312.pyc
|   |       |   |   |           _inspect.cpython-312.pyc
|   |       |   |   |           _log_render.cpython-312.pyc
|   |       |   |   |           _loop.cpython-312.pyc
|   |       |   |   |           _null_file.cpython-312.pyc
|   |       |   |   |           _palettes.cpython-312.pyc
|   |       |   |   |           _pick.cpython-312.pyc
|   |       |   |   |           _ratio.cpython-312.pyc
|   |       |   |   |           _spinners.cpython-312.pyc
|   |       |   |   |           _stack.cpython-312.pyc
|   |       |   |   |           _timer.cpython-312.pyc
|   |       |   |   |           _win32_console.cpython-312.pyc
|   |       |   |   |           _windows.cpython-312.pyc
|   |       |   |   |           _windows_renderer.cpython-312.pyc
|   |       |   |   |           _wrap.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           __main__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---tomli
|   |       |   |   |   |   LICENSE
|   |       |   |   |   |   py.typed
|   |       |   |   |   |   _parser.py
|   |       |   |   |   |   _re.py
|   |       |   |   |   |   _types.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           _parser.cpython-312.pyc
|   |       |   |   |           _re.cpython-312.pyc
|   |       |   |   |           _types.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---tomli_w
|   |       |   |   |   |   LICENSE
|   |       |   |   |   |   py.typed
|   |       |   |   |   |   _writer.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           _writer.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---truststore
|   |       |   |   |   |   LICENSE
|   |       |   |   |   |   py.typed
|   |       |   |   |   |   _api.py
|   |       |   |   |   |   _macos.py
|   |       |   |   |   |   _openssl.py
|   |       |   |   |   |   _ssl_constants.py
|   |       |   |   |   |   _windows.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           _api.cpython-312.pyc
|   |       |   |   |           _macos.cpython-312.pyc
|   |       |   |   |           _openssl.cpython-312.pyc
|   |       |   |   |           _ssl_constants.cpython-312.pyc
|   |       |   |   |           _windows.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---urllib3
|   |       |   |   |   |   connection.py
|   |       |   |   |   |   connectionpool.py
|   |       |   |   |   |   exceptions.py
|   |       |   |   |   |   fields.py
|   |       |   |   |   |   filepost.py
|   |       |   |   |   |   LICENSE.txt
|   |       |   |   |   |   poolmanager.py
|   |       |   |   |   |   request.py
|   |       |   |   |   |   response.py
|   |       |   |   |   |   _collections.py
|   |       |   |   |   |   _version.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   +---contrib
|   |       |   |   |   |   |   appengine.py
|   |       |   |   |   |   |   ntlmpool.py
|   |       |   |   |   |   |   pyopenssl.py
|   |       |   |   |   |   |   securetransport.py
|   |       |   |   |   |   |   socks.py
|   |       |   |   |   |   |   _appengine_environ.py
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   +---_securetransport
|   |       |   |   |   |   |   |   bindings.py
|   |       |   |   |   |   |   |   low_level.py
|   |       |   |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   |   
|   |       |   |   |   |   |   \---__pycache__
|   |       |   |   |   |   |           bindings.cpython-312.pyc
|   |       |   |   |   |   |           low_level.cpython-312.pyc
|   |       |   |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |   |           
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           appengine.cpython-312.pyc
|   |       |   |   |   |           ntlmpool.cpython-312.pyc
|   |       |   |   |   |           pyopenssl.cpython-312.pyc
|   |       |   |   |   |           securetransport.cpython-312.pyc
|   |       |   |   |   |           socks.cpython-312.pyc
|   |       |   |   |   |           _appengine_environ.cpython-312.pyc
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   +---packages
|   |       |   |   |   |   |   six.py
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   +---backports
|   |       |   |   |   |   |   |   makefile.py
|   |       |   |   |   |   |   |   weakref_finalize.py
|   |       |   |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   |   
|   |       |   |   |   |   |   \---__pycache__
|   |       |   |   |   |   |           makefile.cpython-312.pyc
|   |       |   |   |   |   |           weakref_finalize.cpython-312.pyc
|   |       |   |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |   |           
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           six.cpython-312.pyc
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   +---util
|   |       |   |   |   |   |   connection.py
|   |       |   |   |   |   |   proxy.py
|   |       |   |   |   |   |   queue.py
|   |       |   |   |   |   |   request.py
|   |       |   |   |   |   |   response.py
|   |       |   |   |   |   |   retry.py
|   |       |   |   |   |   |   ssltransport.py
|   |       |   |   |   |   |   ssl_.py
|   |       |   |   |   |   |   ssl_match_hostname.py
|   |       |   |   |   |   |   timeout.py
|   |       |   |   |   |   |   url.py
|   |       |   |   |   |   |   wait.py
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           connection.cpython-312.pyc
|   |       |   |   |   |           proxy.cpython-312.pyc
|   |       |   |   |   |           queue.cpython-312.pyc
|   |       |   |   |   |           request.cpython-312.pyc
|   |       |   |   |   |           response.cpython-312.pyc
|   |       |   |   |   |           retry.cpython-312.pyc
|   |       |   |   |   |           ssltransport.cpython-312.pyc
|   |       |   |   |   |           ssl_.cpython-312.pyc
|   |       |   |   |   |           ssl_match_hostname.cpython-312.pyc
|   |       |   |   |   |           timeout.cpython-312.pyc
|   |       |   |   |   |           url.cpython-312.pyc
|   |       |   |   |   |           wait.cpython-312.pyc
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   \---__pycache__
|   |       |   |   |           connection.cpython-312.pyc
|   |       |   |   |           connectionpool.cpython-312.pyc
|   |       |   |   |           exceptions.cpython-312.pyc
|   |       |   |   |           fields.cpython-312.pyc
|   |       |   |   |           filepost.cpython-312.pyc
|   |       |   |   |           poolmanager.cpython-312.pyc
|   |       |   |   |           request.cpython-312.pyc
|   |       |   |   |           response.cpython-312.pyc
|   |       |   |   |           _collections.cpython-312.pyc
|   |       |   |   |           _version.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   \---__pycache__
|   |       |   |           __init__.cpython-312.pyc
|   |       |   |           
|   |       |   \---__pycache__
|   |       |           __init__.cpython-312.pyc
|   |       |           __main__.cpython-312.pyc
|   |       |           __pip-runner__.cpython-312.pyc
|   |       |           
|   |       +---pip-25.3.dist-info
|   |       |   |   entry_points.txt
|   |       |   |   INSTALLER
|   |       |   |   METADATA
|   |       |   |   RECORD
|   |       |   |   REQUESTED
|   |       |   |   WHEEL
|   |       |   |   
|   |       |   \---licenses
|   |       |       |   AUTHORS.txt
|   |       |       |   LICENSE.txt
|   |       |       |   
|   |       |       \---src
|   |       |           \---pip
|   |       |               \---_vendor
|   |       |                   +---cachecontrol
|   |       |                   |       LICENSE.txt
|   |       |                   |       
|   |       |                   +---certifi
|   |       |                   |       LICENSE
|   |       |                   |       
|   |       |                   +---dependency_groups
|   |       |                   |       LICENSE.txt
|   |       |                   |       
|   |       |                   +---distlib
|   |       |                   |       LICENSE.txt
|   |       |                   |       
|   |       |                   +---distro
|   |       |                   |       LICENSE
|   |       |                   |       
|   |       |                   +---idna
|   |       |                   |       LICENSE.md
|   |       |                   |       
|   |       |                   +---msgpack
|   |       |                   |       COPYING
|   |       |                   |       
|   |       |                   +---packaging
|   |       |                   |       LICENSE
|   |       |                   |       LICENSE.APACHE
|   |       |                   |       LICENSE.BSD
|   |       |                   |       
|   |       |                   +---pkg_resources
|   |       |                   |       LICENSE
|   |       |                   |       
|   |       |                   +---platformdirs
|   |       |                   |       LICENSE
|   |       |                   |       
|   |       |                   +---pygments
|   |       |                   |       LICENSE
|   |       |                   |       
|   |       |                   +---pyproject_hooks
|   |       |                   |       LICENSE
|   |       |                   |       
|   |       |                   +---requests
|   |       |                   |       LICENSE
|   |       |                   |       
|   |       |                   +---resolvelib
|   |       |                   |       LICENSE
|   |       |                   |       
|   |       |                   +---rich
|   |       |                   |       LICENSE
|   |       |                   |       
|   |       |                   +---tomli
|   |       |                   |       LICENSE
|   |       |                   |       
|   |       |                   +---tomli_w
|   |       |                   |       LICENSE
|   |       |                   |       
|   |       |                   +---truststore
|   |       |                   |       LICENSE
|   |       |                   |       
|   |       |                   \---urllib3
|   |       |                           LICENSE.txt
|   |       |                           
|   |       +---pkg_resources
|   |       |   |   api_tests.txt
|   |       |   |   py.typed
|   |       |   |   __init__.py
|   |       |   |   
|   |       |   +---tests
|   |       |   |   |   test_find_distributions.py
|   |       |   |   |   test_integration_zope_interface.py
|   |       |   |   |   test_markers.py
|   |       |   |   |   test_pkg_resources.py
|   |       |   |   |   test_resources.py
|   |       |   |   |   test_working_set.py
|   |       |   |   |   __init__.py
|   |       |   |   |   
|   |       |   |   +---data
|   |       |   |   |   +---my-test-package-source
|   |       |   |   |   |   |   setup.cfg
|   |       |   |   |   |   |   setup.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           setup.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   +---my-test-package-zip
|   |       |   |   |   |       my-test-package.zip
|   |       |   |   |   |       
|   |       |   |   |   +---my-test-package_unpacked-egg
|   |       |   |   |   |   \---my_test_package-1.0-py3.7.egg
|   |       |   |   |   |       \---EGG-INFO
|   |       |   |   |   |               dependency_links.txt
|   |       |   |   |   |               PKG-INFO
|   |       |   |   |   |               SOURCES.txt
|   |       |   |   |   |               top_level.txt
|   |       |   |   |   |               zip-safe
|   |       |   |   |   |               
|   |       |   |   |   \---my-test-package_zipped-egg
|   |       |   |   |           my_test_package-1.0-py3.7.egg
|   |       |   |   |           
|   |       |   |   \---__pycache__
|   |       |   |           test_find_distributions.cpython-312.pyc
|   |       |   |           test_integration_zope_interface.cpython-312.pyc
|   |       |   |           test_markers.cpython-312.pyc
|   |       |   |           test_pkg_resources.cpython-312.pyc
|   |       |   |           test_resources.cpython-312.pyc
|   |       |   |           test_working_set.cpython-312.pyc
|   |       |   |           __init__.cpython-312.pyc
|   |       |   |           
|   |       |   \---__pycache__
|   |       |           __init__.cpython-312.pyc
|   |       |           
|   |       +---pydantic
|   |       |   |   aliases.py
|   |       |   |   alias_generators.py
|   |       |   |   annotated_handlers.py
|   |       |   |   class_validators.py
|   |       |   |   color.py
|   |       |   |   config.py
|   |       |   |   dataclasses.py
|   |       |   |   datetime_parse.py
|   |       |   |   decorator.py
|   |       |   |   env_settings.py
|   |       |   |   errors.py
|   |       |   |   error_wrappers.py
|   |       |   |   fields.py
|   |       |   |   functional_serializers.py
|   |       |   |   functional_validators.py
|   |       |   |   generics.py
|   |       |   |   json.py
|   |       |   |   json_schema.py
|   |       |   |   main.py
|   |       |   |   mypy.py
|   |       |   |   networks.py
|   |       |   |   parse.py
|   |       |   |   py.typed
|   |       |   |   root_model.py
|   |       |   |   schema.py
|   |       |   |   tools.py
|   |       |   |   types.py
|   |       |   |   type_adapter.py
|   |       |   |   typing.py
|   |       |   |   utils.py
|   |       |   |   validate_call_decorator.py
|   |       |   |   validators.py
|   |       |   |   version.py
|   |       |   |   warnings.py
|   |       |   |   _migration.py
|   |       |   |   __init__.py
|   |       |   |   
|   |       |   +---deprecated
|   |       |   |   |   class_validators.py
|   |       |   |   |   config.py
|   |       |   |   |   copy_internals.py
|   |       |   |   |   decorator.py
|   |       |   |   |   json.py
|   |       |   |   |   parse.py
|   |       |   |   |   tools.py
|   |       |   |   |   __init__.py
|   |       |   |   |   
|   |       |   |   \---__pycache__
|   |       |   |           class_validators.cpython-312.pyc
|   |       |   |           config.cpython-312.pyc
|   |       |   |           copy_internals.cpython-312.pyc
|   |       |   |           decorator.cpython-312.pyc
|   |       |   |           json.cpython-312.pyc
|   |       |   |           parse.cpython-312.pyc
|   |       |   |           tools.cpython-312.pyc
|   |       |   |           __init__.cpython-312.pyc
|   |       |   |           
|   |       |   +---experimental
|   |       |   |   |   arguments_schema.py
|   |       |   |   |   missing_sentinel.py
|   |       |   |   |   pipeline.py
|   |       |   |   |   __init__.py
|   |       |   |   |   
|   |       |   |   \---__pycache__
|   |       |   |           arguments_schema.cpython-312.pyc
|   |       |   |           missing_sentinel.cpython-312.pyc
|   |       |   |           pipeline.cpython-312.pyc
|   |       |   |           __init__.cpython-312.pyc
|   |       |   |           
|   |       |   +---plugin
|   |       |   |   |   _loader.py
|   |       |   |   |   _schema_validator.py
|   |       |   |   |   __init__.py
|   |       |   |   |   
|   |       |   |   \---__pycache__
|   |       |   |           _loader.cpython-312.pyc
|   |       |   |           _schema_validator.cpython-312.pyc
|   |       |   |           __init__.cpython-312.pyc
|   |       |   |           
|   |       |   +---v1
|   |       |   |   |   annotated_types.py
|   |       |   |   |   class_validators.py
|   |       |   |   |   color.py
|   |       |   |   |   config.py
|   |       |   |   |   dataclasses.py
|   |       |   |   |   datetime_parse.py
|   |       |   |   |   decorator.py
|   |       |   |   |   env_settings.py
|   |       |   |   |   errors.py
|   |       |   |   |   error_wrappers.py
|   |       |   |   |   fields.py
|   |       |   |   |   generics.py
|   |       |   |   |   json.py
|   |       |   |   |   main.py
|   |       |   |   |   mypy.py
|   |       |   |   |   networks.py
|   |       |   |   |   parse.py
|   |       |   |   |   py.typed
|   |       |   |   |   schema.py
|   |       |   |   |   tools.py
|   |       |   |   |   types.py
|   |       |   |   |   typing.py
|   |       |   |   |   utils.py
|   |       |   |   |   validators.py
|   |       |   |   |   version.py
|   |       |   |   |   _hypothesis_plugin.py
|   |       |   |   |   __init__.py
|   |       |   |   |   
|   |       |   |   \---__pycache__
|   |       |   |           annotated_types.cpython-312.pyc
|   |       |   |           class_validators.cpython-312.pyc
|   |       |   |           color.cpython-312.pyc
|   |       |   |           config.cpython-312.pyc
|   |       |   |           dataclasses.cpython-312.pyc
|   |       |   |           datetime_parse.cpython-312.pyc
|   |       |   |           decorator.cpython-312.pyc
|   |       |   |           env_settings.cpython-312.pyc
|   |       |   |           errors.cpython-312.pyc
|   |       |   |           error_wrappers.cpython-312.pyc
|   |       |   |           fields.cpython-312.pyc
|   |       |   |           generics.cpython-312.pyc
|   |       |   |           json.cpython-312.pyc
|   |       |   |           main.cpython-312.pyc
|   |       |   |           mypy.cpython-312.pyc
|   |       |   |           networks.cpython-312.pyc
|   |       |   |           parse.cpython-312.pyc
|   |       |   |           schema.cpython-312.pyc
|   |       |   |           tools.cpython-312.pyc
|   |       |   |           types.cpython-312.pyc
|   |       |   |           typing.cpython-312.pyc
|   |       |   |           utils.cpython-312.pyc
|   |       |   |           validators.cpython-312.pyc
|   |       |   |           version.cpython-312.pyc
|   |       |   |           _hypothesis_plugin.cpython-312.pyc
|   |       |   |           __init__.cpython-312.pyc
|   |       |   |           
|   |       |   +---_internal
|   |       |   |   |   _config.py
|   |       |   |   |   _core_metadata.py
|   |       |   |   |   _core_utils.py
|   |       |   |   |   _dataclasses.py
|   |       |   |   |   _decorators.py
|   |       |   |   |   _decorators_v1.py
|   |       |   |   |   _discriminated_union.py
|   |       |   |   |   _docs_extraction.py
|   |       |   |   |   _fields.py
|   |       |   |   |   _forward_ref.py
|   |       |   |   |   _generate_schema.py
|   |       |   |   |   _generics.py
|   |       |   |   |   _git.py
|   |       |   |   |   _import_utils.py
|   |       |   |   |   _internal_dataclass.py
|   |       |   |   |   _known_annotated_metadata.py
|   |       |   |   |   _mock_val_ser.py
|   |       |   |   |   _model_construction.py
|   |       |   |   |   _namespace_utils.py
|   |       |   |   |   _repr.py
|   |       |   |   |   _schema_gather.py
|   |       |   |   |   _schema_generation_shared.py
|   |       |   |   |   _serializers.py
|   |       |   |   |   _signature.py
|   |       |   |   |   _typing_extra.py
|   |       |   |   |   _utils.py
|   |       |   |   |   _validate_call.py
|   |       |   |   |   _validators.py
|   |       |   |   |   __init__.py
|   |       |   |   |   
|   |       |   |   \---__pycache__
|   |       |   |           _config.cpython-312.pyc
|   |       |   |           _core_metadata.cpython-312.pyc
|   |       |   |           _core_utils.cpython-312.pyc
|   |       |   |           _dataclasses.cpython-312.pyc
|   |       |   |           _decorators.cpython-312.pyc
|   |       |   |           _decorators_v1.cpython-312.pyc
|   |       |   |           _discriminated_union.cpython-312.pyc
|   |       |   |           _docs_extraction.cpython-312.pyc
|   |       |   |           _fields.cpython-312.pyc
|   |       |   |           _forward_ref.cpython-312.pyc
|   |       |   |           _generate_schema.cpython-312.pyc
|   |       |   |           _generics.cpython-312.pyc
|   |       |   |           _git.cpython-312.pyc
|   |       |   |           _import_utils.cpython-312.pyc
|   |       |   |           _internal_dataclass.cpython-312.pyc
|   |       |   |           _known_annotated_metadata.cpython-312.pyc
|   |       |   |           _mock_val_ser.cpython-312.pyc
|   |       |   |           _model_construction.cpython-312.pyc
|   |       |   |           _namespace_utils.cpython-312.pyc
|   |       |   |           _repr.cpython-312.pyc
|   |       |   |           _schema_gather.cpython-312.pyc
|   |       |   |           _schema_generation_shared.cpython-312.pyc
|   |       |   |           _serializers.cpython-312.pyc
|   |       |   |           _signature.cpython-312.pyc
|   |       |   |           _typing_extra.cpython-312.pyc
|   |       |   |           _utils.cpython-312.pyc
|   |       |   |           _validate_call.cpython-312.pyc
|   |       |   |           _validators.cpython-312.pyc
|   |       |   |           __init__.cpython-312.pyc
|   |       |   |           
|   |       |   \---__pycache__
|   |       |           aliases.cpython-312.pyc
|   |       |           alias_generators.cpython-312.pyc
|   |       |           annotated_handlers.cpython-312.pyc
|   |       |           class_validators.cpython-312.pyc
|   |       |           color.cpython-312.pyc
|   |       |           config.cpython-312.pyc
|   |       |           dataclasses.cpython-312.pyc
|   |       |           datetime_parse.cpython-312.pyc
|   |       |           decorator.cpython-312.pyc
|   |       |           env_settings.cpython-312.pyc
|   |       |           errors.cpython-312.pyc
|   |       |           error_wrappers.cpython-312.pyc
|   |       |           fields.cpython-312.pyc
|   |       |           functional_serializers.cpython-312.pyc
|   |       |           functional_validators.cpython-312.pyc
|   |       |           generics.cpython-312.pyc
|   |       |           json.cpython-312.pyc
|   |       |           json_schema.cpython-312.pyc
|   |       |           main.cpython-312.pyc
|   |       |           mypy.cpython-312.pyc
|   |       |           networks.cpython-312.pyc
|   |       |           parse.cpython-312.pyc
|   |       |           root_model.cpython-312.pyc
|   |       |           schema.cpython-312.pyc
|   |       |           tools.cpython-312.pyc
|   |       |           types.cpython-312.pyc
|   |       |           type_adapter.cpython-312.pyc
|   |       |           typing.cpython-312.pyc
|   |       |           utils.cpython-312.pyc
|   |       |           validate_call_decorator.cpython-312.pyc
|   |       |           validators.cpython-312.pyc
|   |       |           version.cpython-312.pyc
|   |       |           warnings.cpython-312.pyc
|   |       |           _migration.cpython-312.pyc
|   |       |           __init__.cpython-312.pyc
|   |       |           
|   |       +---pydantic-2.12.5.dist-info
|   |       |   |   INSTALLER
|   |       |   |   METADATA
|   |       |   |   RECORD
|   |       |   |   WHEEL
|   |       |   |   
|   |       |   \---licenses
|   |       |           LICENSE
|   |       |           
|   |       +---pydantic_core
|   |       |   |   core_schema.py
|   |       |   |   py.typed
|   |       |   |   _pydantic_core.cp312-win_amd64.pyd
|   |       |   |   _pydantic_core.pyi
|   |       |   |   __init__.py
|   |       |   |   
|   |       |   \---__pycache__
|   |       |           core_schema.cpython-312.pyc
|   |       |           __init__.cpython-312.pyc
|   |       |           
|   |       +---pydantic_core-2.41.5.dist-info
|   |       |   |   INSTALLER
|   |       |   |   METADATA
|   |       |   |   RECORD
|   |       |   |   WHEEL
|   |       |   |   
|   |       |   \---licenses
|   |       |           LICENSE
|   |       |           
|   |       +---pyyaml-6.0.3.dist-info
|   |       |   |   INSTALLER
|   |       |   |   METADATA
|   |       |   |   RECORD
|   |       |   |   top_level.txt
|   |       |   |   WHEEL
|   |       |   |   
|   |       |   \---licenses
|   |       |           LICENSE
|   |       |           
|   |       +---requests
|   |       |   |   adapters.py
|   |       |   |   api.py
|   |       |   |   auth.py
|   |       |   |   certs.py
|   |       |   |   compat.py
|   |       |   |   cookies.py
|   |       |   |   exceptions.py
|   |       |   |   help.py
|   |       |   |   hooks.py
|   |       |   |   models.py
|   |       |   |   packages.py
|   |       |   |   sessions.py
|   |       |   |   status_codes.py
|   |       |   |   structures.py
|   |       |   |   utils.py
|   |       |   |   _internal_utils.py
|   |       |   |   __init__.py
|   |       |   |   __version__.py
|   |       |   |   
|   |       |   \---__pycache__
|   |       |           adapters.cpython-312.pyc
|   |       |           api.cpython-312.pyc
|   |       |           auth.cpython-312.pyc
|   |       |           certs.cpython-312.pyc
|   |       |           compat.cpython-312.pyc
|   |       |           cookies.cpython-312.pyc
|   |       |           exceptions.cpython-312.pyc
|   |       |           help.cpython-312.pyc
|   |       |           hooks.cpython-312.pyc
|   |       |           models.cpython-312.pyc
|   |       |           packages.cpython-312.pyc
|   |       |           sessions.cpython-312.pyc
|   |       |           status_codes.cpython-312.pyc
|   |       |           structures.cpython-312.pyc
|   |       |           utils.cpython-312.pyc
|   |       |           _internal_utils.cpython-312.pyc
|   |       |           __init__.cpython-312.pyc
|   |       |           __version__.cpython-312.pyc
|   |       |           
|   |       +---requests-2.32.5.dist-info
|   |       |   |   INSTALLER
|   |       |   |   METADATA
|   |       |   |   RECORD
|   |       |   |   top_level.txt
|   |       |   |   WHEEL
|   |       |   |   
|   |       |   \---licenses
|   |       |           LICENSE
|   |       |           
|   |       +---rylan_unifi_case_study-0.1.0.dist-info
|   |       |   |   direct_url.json
|   |       |   |   INSTALLER
|   |       |   |   METADATA
|   |       |   |   RECORD
|   |       |   |   REQUESTED
|   |       |   |   top_level.txt
|   |       |   |   WHEEL
|   |       |   |   
|   |       |   \---licenses
|   |       |           LICENSE
|   |       |           
|   |       +---setuptools
|   |       |   |   archive_util.py
|   |       |   |   build_meta.py
|   |       |   |   cli-32.exe
|   |       |   |   cli-64.exe
|   |       |   |   cli-arm64.exe
|   |       |   |   cli.exe
|   |       |   |   depends.py
|   |       |   |   discovery.py
|   |       |   |   dist.py
|   |       |   |   errors.py
|   |       |   |   extension.py
|   |       |   |   glob.py
|   |       |   |   gui-32.exe
|   |       |   |   gui-64.exe
|   |       |   |   gui-arm64.exe
|   |       |   |   gui.exe
|   |       |   |   installer.py
|   |       |   |   launch.py
|   |       |   |   logging.py
|   |       |   |   modified.py
|   |       |   |   monkey.py
|   |       |   |   msvc.py
|   |       |   |   namespaces.py
|   |       |   |   script (dev).tmpl
|   |       |   |   script.tmpl
|   |       |   |   unicode_utils.py
|   |       |   |   version.py
|   |       |   |   warnings.py
|   |       |   |   wheel.py
|   |       |   |   windows_support.py
|   |       |   |   _core_metadata.py
|   |       |   |   _discovery.py
|   |       |   |   _entry_points.py
|   |       |   |   _imp.py
|   |       |   |   _importlib.py
|   |       |   |   _itertools.py
|   |       |   |   _normalization.py
|   |       |   |   _path.py
|   |       |   |   _reqs.py
|   |       |   |   _scripts.py
|   |       |   |   _shutil.py
|   |       |   |   _static.py
|   |       |   |   __init__.py
|   |       |   |   
|   |       |   +---command
|   |       |   |   |   alias.py
|   |       |   |   |   bdist_egg.py
|   |       |   |   |   bdist_rpm.py
|   |       |   |   |   bdist_wheel.py
|   |       |   |   |   build.py
|   |       |   |   |   build_clib.py
|   |       |   |   |   build_ext.py
|   |       |   |   |   build_py.py
|   |       |   |   |   develop.py
|   |       |   |   |   dist_info.py
|   |       |   |   |   easy_install.py
|   |       |   |   |   editable_wheel.py
|   |       |   |   |   egg_info.py
|   |       |   |   |   install.py
|   |       |   |   |   install_egg_info.py
|   |       |   |   |   install_lib.py
|   |       |   |   |   install_scripts.py
|   |       |   |   |   launcher manifest.xml
|   |       |   |   |   rotate.py
|   |       |   |   |   saveopts.py
|   |       |   |   |   sdist.py
|   |       |   |   |   setopt.py
|   |       |   |   |   test.py
|   |       |   |   |   _requirestxt.py
|   |       |   |   |   __init__.py
|   |       |   |   |   
|   |       |   |   \---__pycache__
|   |       |   |           alias.cpython-312.pyc
|   |       |   |           bdist_egg.cpython-312.pyc
|   |       |   |           bdist_rpm.cpython-312.pyc
|   |       |   |           bdist_wheel.cpython-312.pyc
|   |       |   |           build.cpython-312.pyc
|   |       |   |           build_clib.cpython-312.pyc
|   |       |   |           build_ext.cpython-312.pyc
|   |       |   |           build_py.cpython-312.pyc
|   |       |   |           develop.cpython-312.pyc
|   |       |   |           dist_info.cpython-312.pyc
|   |       |   |           easy_install.cpython-312.pyc
|   |       |   |           editable_wheel.cpython-312.pyc
|   |       |   |           egg_info.cpython-312.pyc
|   |       |   |           install.cpython-312.pyc
|   |       |   |           install_egg_info.cpython-312.pyc
|   |       |   |           install_lib.cpython-312.pyc
|   |       |   |           install_scripts.cpython-312.pyc
|   |       |   |           rotate.cpython-312.pyc
|   |       |   |           saveopts.cpython-312.pyc
|   |       |   |           sdist.cpython-312.pyc
|   |       |   |           setopt.cpython-312.pyc
|   |       |   |           test.cpython-312.pyc
|   |       |   |           _requirestxt.cpython-312.pyc
|   |       |   |           __init__.cpython-312.pyc
|   |       |   |           
|   |       |   +---compat
|   |       |   |   |   py310.py
|   |       |   |   |   py311.py
|   |       |   |   |   py312.py
|   |       |   |   |   py39.py
|   |       |   |   |   __init__.py
|   |       |   |   |   
|   |       |   |   \---__pycache__
|   |       |   |           py310.cpython-312.pyc
|   |       |   |           py311.cpython-312.pyc
|   |       |   |           py312.cpython-312.pyc
|   |       |   |           py39.cpython-312.pyc
|   |       |   |           __init__.cpython-312.pyc
|   |       |   |           
|   |       |   +---config
|   |       |   |   |   distutils.schema.json
|   |       |   |   |   expand.py
|   |       |   |   |   NOTICE
|   |       |   |   |   pyprojecttoml.py
|   |       |   |   |   setupcfg.py
|   |       |   |   |   setuptools.schema.json
|   |       |   |   |   _apply_pyprojecttoml.py
|   |       |   |   |   __init__.py
|   |       |   |   |   
|   |       |   |   +---_validate_pyproject
|   |       |   |   |   |   error_reporting.py
|   |       |   |   |   |   extra_validations.py
|   |       |   |   |   |   fastjsonschema_exceptions.py
|   |       |   |   |   |   fastjsonschema_validations.py
|   |       |   |   |   |   formats.py
|   |       |   |   |   |   NOTICE
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           error_reporting.cpython-312.pyc
|   |       |   |   |           extra_validations.cpython-312.pyc
|   |       |   |   |           fastjsonschema_exceptions.cpython-312.pyc
|   |       |   |   |           fastjsonschema_validations.cpython-312.pyc
|   |       |   |   |           formats.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   \---__pycache__
|   |       |   |           expand.cpython-312.pyc
|   |       |   |           pyprojecttoml.cpython-312.pyc
|   |       |   |           setupcfg.cpython-312.pyc
|   |       |   |           _apply_pyprojecttoml.cpython-312.pyc
|   |       |   |           __init__.cpython-312.pyc
|   |       |   |           
|   |       |   +---tests
|   |       |   |   |   contexts.py
|   |       |   |   |   environment.py
|   |       |   |   |   fixtures.py
|   |       |   |   |   mod_with_constant.py
|   |       |   |   |   namespaces.py
|   |       |   |   |   script-with-bom.py
|   |       |   |   |   test_archive_util.py
|   |       |   |   |   test_bdist_deprecations.py
|   |       |   |   |   test_bdist_egg.py
|   |       |   |   |   test_bdist_wheel.py
|   |       |   |   |   test_build.py
|   |       |   |   |   test_build_clib.py
|   |       |   |   |   test_build_ext.py
|   |       |   |   |   test_build_meta.py
|   |       |   |   |   test_build_py.py
|   |       |   |   |   test_config_discovery.py
|   |       |   |   |   test_core_metadata.py
|   |       |   |   |   test_depends.py
|   |       |   |   |   test_develop.py
|   |       |   |   |   test_dist.py
|   |       |   |   |   test_distutils_adoption.py
|   |       |   |   |   test_dist_info.py
|   |       |   |   |   test_editable_install.py
|   |       |   |   |   test_egg_info.py
|   |       |   |   |   test_extern.py
|   |       |   |   |   test_find_packages.py
|   |       |   |   |   test_find_py_modules.py
|   |       |   |   |   test_glob.py
|   |       |   |   |   test_install_scripts.py
|   |       |   |   |   test_logging.py
|   |       |   |   |   test_manifest.py
|   |       |   |   |   test_namespaces.py
|   |       |   |   |   test_scripts.py
|   |       |   |   |   test_sdist.py
|   |       |   |   |   test_setopt.py
|   |       |   |   |   test_setuptools.py
|   |       |   |   |   test_shutil_wrapper.py
|   |       |   |   |   test_unicode_utils.py
|   |       |   |   |   test_virtualenv.py
|   |       |   |   |   test_warnings.py
|   |       |   |   |   test_wheel.py
|   |       |   |   |   test_windows_wrappers.py
|   |       |   |   |   text.py
|   |       |   |   |   textwrap.py
|   |       |   |   |   __init__.py
|   |       |   |   |   
|   |       |   |   +---compat
|   |       |   |   |   |   py39.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           py39.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---config
|   |       |   |   |   |   setupcfg_examples.txt
|   |       |   |   |   |   test_apply_pyprojecttoml.py
|   |       |   |   |   |   test_expand.py
|   |       |   |   |   |   test_pyprojecttoml.py
|   |       |   |   |   |   test_pyprojecttoml_dynamic_deps.py
|   |       |   |   |   |   test_setupcfg.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   +---downloads
|   |       |   |   |   |   |   preload.py
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           preload.cpython-312.pyc
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   \---__pycache__
|   |       |   |   |           test_apply_pyprojecttoml.cpython-312.pyc
|   |       |   |   |           test_expand.cpython-312.pyc
|   |       |   |   |           test_pyprojecttoml.cpython-312.pyc
|   |       |   |   |           test_pyprojecttoml_dynamic_deps.cpython-312.pyc
|   |       |   |   |           test_setupcfg.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---indexes
|   |       |   |   |   \---test_links_priority
|   |       |   |   |       |   external.html
|   |       |   |   |       |   
|   |       |   |   |       \---simple
|   |       |   |   |           \---foobar
|   |       |   |   |                   index.html
|   |       |   |   |                   
|   |       |   |   +---integration
|   |       |   |   |   |   helpers.py
|   |       |   |   |   |   test_pbr.py
|   |       |   |   |   |   test_pip_install_sdist.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           helpers.cpython-312.pyc
|   |       |   |   |           test_pbr.cpython-312.pyc
|   |       |   |   |           test_pip_install_sdist.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   \---__pycache__
|   |       |   |           contexts.cpython-312.pyc
|   |       |   |           environment.cpython-312.pyc
|   |       |   |           fixtures.cpython-312.pyc
|   |       |   |           mod_with_constant.cpython-312.pyc
|   |       |   |           namespaces.cpython-312.pyc
|   |       |   |           script-with-bom.cpython-312.pyc
|   |       |   |           test_archive_util.cpython-312.pyc
|   |       |   |           test_bdist_deprecations.cpython-312.pyc
|   |       |   |           test_bdist_egg.cpython-312.pyc
|   |       |   |           test_bdist_wheel.cpython-312.pyc
|   |       |   |           test_build.cpython-312.pyc
|   |       |   |           test_build_clib.cpython-312.pyc
|   |       |   |           test_build_ext.cpython-312.pyc
|   |       |   |           test_build_meta.cpython-312.pyc
|   |       |   |           test_build_py.cpython-312.pyc
|   |       |   |           test_config_discovery.cpython-312.pyc
|   |       |   |           test_core_metadata.cpython-312.pyc
|   |       |   |           test_depends.cpython-312.pyc
|   |       |   |           test_develop.cpython-312.pyc
|   |       |   |           test_dist.cpython-312.pyc
|   |       |   |           test_distutils_adoption.cpython-312.pyc
|   |       |   |           test_dist_info.cpython-312.pyc
|   |       |   |           test_editable_install.cpython-312.pyc
|   |       |   |           test_egg_info.cpython-312.pyc
|   |       |   |           test_extern.cpython-312.pyc
|   |       |   |           test_find_packages.cpython-312.pyc
|   |       |   |           test_find_py_modules.cpython-312.pyc
|   |       |   |           test_glob.cpython-312.pyc
|   |       |   |           test_install_scripts.cpython-312.pyc
|   |       |   |           test_logging.cpython-312.pyc
|   |       |   |           test_manifest.cpython-312.pyc
|   |       |   |           test_namespaces.cpython-312.pyc
|   |       |   |           test_scripts.cpython-312.pyc
|   |       |   |           test_sdist.cpython-312.pyc
|   |       |   |           test_setopt.cpython-312.pyc
|   |       |   |           test_setuptools.cpython-312.pyc
|   |       |   |           test_shutil_wrapper.cpython-312.pyc
|   |       |   |           test_unicode_utils.cpython-312.pyc
|   |       |   |           test_virtualenv.cpython-312.pyc
|   |       |   |           test_warnings.cpython-312.pyc
|   |       |   |           test_wheel.cpython-312.pyc
|   |       |   |           test_windows_wrappers.cpython-312.pyc
|   |       |   |           text.cpython-312.pyc
|   |       |   |           textwrap.cpython-312.pyc
|   |       |   |           __init__.cpython-312.pyc
|   |       |   |           
|   |       |   +---_distutils
|   |       |   |   |   archive_util.py
|   |       |   |   |   ccompiler.py
|   |       |   |   |   cmd.py
|   |       |   |   |   core.py
|   |       |   |   |   cygwinccompiler.py
|   |       |   |   |   debug.py
|   |       |   |   |   dep_util.py
|   |       |   |   |   dir_util.py
|   |       |   |   |   dist.py
|   |       |   |   |   errors.py
|   |       |   |   |   extension.py
|   |       |   |   |   fancy_getopt.py
|   |       |   |   |   filelist.py
|   |       |   |   |   file_util.py
|   |       |   |   |   log.py
|   |       |   |   |   spawn.py
|   |       |   |   |   sysconfig.py
|   |       |   |   |   text_file.py
|   |       |   |   |   unixccompiler.py
|   |       |   |   |   util.py
|   |       |   |   |   version.py
|   |       |   |   |   versionpredicate.py
|   |       |   |   |   zosccompiler.py
|   |       |   |   |   _log.py
|   |       |   |   |   _macos_compat.py
|   |       |   |   |   _modified.py
|   |       |   |   |   _msvccompiler.py
|   |       |   |   |   __init__.py
|   |       |   |   |   
|   |       |   |   +---command
|   |       |   |   |   |   bdist.py
|   |       |   |   |   |   bdist_dumb.py
|   |       |   |   |   |   bdist_rpm.py
|   |       |   |   |   |   build.py
|   |       |   |   |   |   build_clib.py
|   |       |   |   |   |   build_ext.py
|   |       |   |   |   |   build_py.py
|   |       |   |   |   |   build_scripts.py
|   |       |   |   |   |   check.py
|   |       |   |   |   |   clean.py
|   |       |   |   |   |   config.py
|   |       |   |   |   |   install.py
|   |       |   |   |   |   install_data.py
|   |       |   |   |   |   install_egg_info.py
|   |       |   |   |   |   install_headers.py
|   |       |   |   |   |   install_lib.py
|   |       |   |   |   |   install_scripts.py
|   |       |   |   |   |   sdist.py
|   |       |   |   |   |   _framework_compat.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           bdist.cpython-312.pyc
|   |       |   |   |           bdist_dumb.cpython-312.pyc
|   |       |   |   |           bdist_rpm.cpython-312.pyc
|   |       |   |   |           build.cpython-312.pyc
|   |       |   |   |           build_clib.cpython-312.pyc
|   |       |   |   |           build_ext.cpython-312.pyc
|   |       |   |   |           build_py.cpython-312.pyc
|   |       |   |   |           build_scripts.cpython-312.pyc
|   |       |   |   |           check.cpython-312.pyc
|   |       |   |   |           clean.cpython-312.pyc
|   |       |   |   |           config.cpython-312.pyc
|   |       |   |   |           install.cpython-312.pyc
|   |       |   |   |           install_data.cpython-312.pyc
|   |       |   |   |           install_egg_info.cpython-312.pyc
|   |       |   |   |           install_headers.cpython-312.pyc
|   |       |   |   |           install_lib.cpython-312.pyc
|   |       |   |   |           install_scripts.cpython-312.pyc
|   |       |   |   |           sdist.cpython-312.pyc
|   |       |   |   |           _framework_compat.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---compat
|   |       |   |   |   |   numpy.py
|   |       |   |   |   |   py39.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           numpy.cpython-312.pyc
|   |       |   |   |           py39.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---compilers
|   |       |   |   |   \---C
|   |       |   |   |       |   base.py
|   |       |   |   |       |   cygwin.py
|   |       |   |   |       |   errors.py
|   |       |   |   |       |   msvc.py
|   |       |   |   |       |   unix.py
|   |       |   |   |       |   zos.py
|   |       |   |   |       |   
|   |       |   |   |       +---tests
|   |       |   |   |       |   |   test_base.py
|   |       |   |   |       |   |   test_cygwin.py
|   |       |   |   |       |   |   test_mingw.py
|   |       |   |   |       |   |   test_msvc.py
|   |       |   |   |       |   |   test_unix.py
|   |       |   |   |       |   |   
|   |       |   |   |       |   \---__pycache__
|   |       |   |   |       |           test_base.cpython-312.pyc
|   |       |   |   |       |           test_cygwin.cpython-312.pyc
|   |       |   |   |       |           test_mingw.cpython-312.pyc
|   |       |   |   |       |           test_msvc.cpython-312.pyc
|   |       |   |   |       |           test_unix.cpython-312.pyc
|   |       |   |   |       |           
|   |       |   |   |       \---__pycache__
|   |       |   |   |               base.cpython-312.pyc
|   |       |   |   |               cygwin.cpython-312.pyc
|   |       |   |   |               errors.cpython-312.pyc
|   |       |   |   |               msvc.cpython-312.pyc
|   |       |   |   |               unix.cpython-312.pyc
|   |       |   |   |               zos.cpython-312.pyc
|   |       |   |   |               
|   |       |   |   +---tests
|   |       |   |   |   |   support.py
|   |       |   |   |   |   test_archive_util.py
|   |       |   |   |   |   test_bdist.py
|   |       |   |   |   |   test_bdist_dumb.py
|   |       |   |   |   |   test_bdist_rpm.py
|   |       |   |   |   |   test_build.py
|   |       |   |   |   |   test_build_clib.py
|   |       |   |   |   |   test_build_ext.py
|   |       |   |   |   |   test_build_py.py
|   |       |   |   |   |   test_build_scripts.py
|   |       |   |   |   |   test_check.py
|   |       |   |   |   |   test_clean.py
|   |       |   |   |   |   test_cmd.py
|   |       |   |   |   |   test_config_cmd.py
|   |       |   |   |   |   test_core.py
|   |       |   |   |   |   test_dir_util.py
|   |       |   |   |   |   test_dist.py
|   |       |   |   |   |   test_extension.py
|   |       |   |   |   |   test_filelist.py
|   |       |   |   |   |   test_file_util.py
|   |       |   |   |   |   test_install.py
|   |       |   |   |   |   test_install_data.py
|   |       |   |   |   |   test_install_headers.py
|   |       |   |   |   |   test_install_lib.py
|   |       |   |   |   |   test_install_scripts.py
|   |       |   |   |   |   test_log.py
|   |       |   |   |   |   test_modified.py
|   |       |   |   |   |   test_sdist.py
|   |       |   |   |   |   test_spawn.py
|   |       |   |   |   |   test_sysconfig.py
|   |       |   |   |   |   test_text_file.py
|   |       |   |   |   |   test_util.py
|   |       |   |   |   |   test_version.py
|   |       |   |   |   |   test_versionpredicate.py
|   |       |   |   |   |   unix_compat.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   +---compat
|   |       |   |   |   |   |   py39.py
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           py39.cpython-312.pyc
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   \---__pycache__
|   |       |   |   |           support.cpython-312.pyc
|   |       |   |   |           test_archive_util.cpython-312.pyc
|   |       |   |   |           test_bdist.cpython-312.pyc
|   |       |   |   |           test_bdist_dumb.cpython-312.pyc
|   |       |   |   |           test_bdist_rpm.cpython-312.pyc
|   |       |   |   |           test_build.cpython-312.pyc
|   |       |   |   |           test_build_clib.cpython-312.pyc
|   |       |   |   |           test_build_ext.cpython-312.pyc
|   |       |   |   |           test_build_py.cpython-312.pyc
|   |       |   |   |           test_build_scripts.cpython-312.pyc
|   |       |   |   |           test_check.cpython-312.pyc
|   |       |   |   |           test_clean.cpython-312.pyc
|   |       |   |   |           test_cmd.cpython-312.pyc
|   |       |   |   |           test_config_cmd.cpython-312.pyc
|   |       |   |   |           test_core.cpython-312.pyc
|   |       |   |   |           test_dir_util.cpython-312.pyc
|   |       |   |   |           test_dist.cpython-312.pyc
|   |       |   |   |           test_extension.cpython-312.pyc
|   |       |   |   |           test_filelist.cpython-312.pyc
|   |       |   |   |           test_file_util.cpython-312.pyc
|   |       |   |   |           test_install.cpython-312.pyc
|   |       |   |   |           test_install_data.cpython-312.pyc
|   |       |   |   |           test_install_headers.cpython-312.pyc
|   |       |   |   |           test_install_lib.cpython-312.pyc
|   |       |   |   |           test_install_scripts.cpython-312.pyc
|   |       |   |   |           test_log.cpython-312.pyc
|   |       |   |   |           test_modified.cpython-312.pyc
|   |       |   |   |           test_sdist.cpython-312.pyc
|   |       |   |   |           test_spawn.cpython-312.pyc
|   |       |   |   |           test_sysconfig.cpython-312.pyc
|   |       |   |   |           test_text_file.cpython-312.pyc
|   |       |   |   |           test_util.cpython-312.pyc
|   |       |   |   |           test_version.cpython-312.pyc
|   |       |   |   |           test_versionpredicate.cpython-312.pyc
|   |       |   |   |           unix_compat.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   \---__pycache__
|   |       |   |           archive_util.cpython-312.pyc
|   |       |   |           ccompiler.cpython-312.pyc
|   |       |   |           cmd.cpython-312.pyc
|   |       |   |           core.cpython-312.pyc
|   |       |   |           cygwinccompiler.cpython-312.pyc
|   |       |   |           debug.cpython-312.pyc
|   |       |   |           dep_util.cpython-312.pyc
|   |       |   |           dir_util.cpython-312.pyc
|   |       |   |           dist.cpython-312.pyc
|   |       |   |           errors.cpython-312.pyc
|   |       |   |           extension.cpython-312.pyc
|   |       |   |           fancy_getopt.cpython-312.pyc
|   |       |   |           filelist.cpython-312.pyc
|   |       |   |           file_util.cpython-312.pyc
|   |       |   |           log.cpython-312.pyc
|   |       |   |           spawn.cpython-312.pyc
|   |       |   |           sysconfig.cpython-312.pyc
|   |       |   |           text_file.cpython-312.pyc
|   |       |   |           unixccompiler.cpython-312.pyc
|   |       |   |           util.cpython-312.pyc
|   |       |   |           version.cpython-312.pyc
|   |       |   |           versionpredicate.cpython-312.pyc
|   |       |   |           zosccompiler.cpython-312.pyc
|   |       |   |           _log.cpython-312.pyc
|   |       |   |           _macos_compat.cpython-312.pyc
|   |       |   |           _modified.cpython-312.pyc
|   |       |   |           _msvccompiler.cpython-312.pyc
|   |       |   |           __init__.cpython-312.pyc
|   |       |   |           
|   |       |   +---_vendor
|   |       |   |   |   typing_extensions.py
|   |       |   |   |   
|   |       |   |   +---autocommand
|   |       |   |   |   |   autoasync.py
|   |       |   |   |   |   autocommand.py
|   |       |   |   |   |   automain.py
|   |       |   |   |   |   autoparse.py
|   |       |   |   |   |   errors.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           autoasync.cpython-312.pyc
|   |       |   |   |           autocommand.cpython-312.pyc
|   |       |   |   |           automain.cpython-312.pyc
|   |       |   |   |           autoparse.cpython-312.pyc
|   |       |   |   |           errors.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---autocommand-2.2.2.dist-info
|   |       |   |   |       INSTALLER
|   |       |   |   |       LICENSE
|   |       |   |   |       METADATA
|   |       |   |   |       RECORD
|   |       |   |   |       top_level.txt
|   |       |   |   |       WHEEL
|   |       |   |   |       
|   |       |   |   +---backports
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   +---tarfile
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   __main__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   +---compat
|   |       |   |   |   |   |   |   py38.py
|   |       |   |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   |   
|   |       |   |   |   |   |   \---__pycache__
|   |       |   |   |   |   |           py38.cpython-312.pyc
|   |       |   |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |   |           
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           __main__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   \---__pycache__
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---backports.tarfile-1.2.0.dist-info
|   |       |   |   |       INSTALLER
|   |       |   |   |       LICENSE
|   |       |   |   |       METADATA
|   |       |   |   |       RECORD
|   |       |   |   |       REQUESTED
|   |       |   |   |       top_level.txt
|   |       |   |   |       WHEEL
|   |       |   |   |       
|   |       |   |   +---importlib_metadata
|   |       |   |   |   |   diagnose.py
|   |       |   |   |   |   py.typed
|   |       |   |   |   |   _adapters.py
|   |       |   |   |   |   _collections.py
|   |       |   |   |   |   _compat.py
|   |       |   |   |   |   _functools.py
|   |       |   |   |   |   _itertools.py
|   |       |   |   |   |   _meta.py
|   |       |   |   |   |   _text.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   +---compat
|   |       |   |   |   |   |   py311.py
|   |       |   |   |   |   |   py39.py
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           py311.cpython-312.pyc
|   |       |   |   |   |           py39.cpython-312.pyc
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   \---__pycache__
|   |       |   |   |           diagnose.cpython-312.pyc
|   |       |   |   |           _adapters.cpython-312.pyc
|   |       |   |   |           _collections.cpython-312.pyc
|   |       |   |   |           _compat.cpython-312.pyc
|   |       |   |   |           _functools.cpython-312.pyc
|   |       |   |   |           _itertools.cpython-312.pyc
|   |       |   |   |           _meta.cpython-312.pyc
|   |       |   |   |           _text.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---importlib_metadata-8.0.0.dist-info
|   |       |   |   |       INSTALLER
|   |       |   |   |       LICENSE
|   |       |   |   |       METADATA
|   |       |   |   |       RECORD
|   |       |   |   |       REQUESTED
|   |       |   |   |       top_level.txt
|   |       |   |   |       WHEEL
|   |       |   |   |       
|   |       |   |   +---inflect
|   |       |   |   |   |   py.typed
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   +---compat
|   |       |   |   |   |   |   py38.py
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           py38.cpython-312.pyc
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   \---__pycache__
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---inflect-7.3.1.dist-info
|   |       |   |   |       INSTALLER
|   |       |   |   |       LICENSE
|   |       |   |   |       METADATA
|   |       |   |   |       RECORD
|   |       |   |   |       top_level.txt
|   |       |   |   |       WHEEL
|   |       |   |   |       
|   |       |   |   +---jaraco
|   |       |   |   |   |   context.py
|   |       |   |   |   |   
|   |       |   |   |   +---collections
|   |       |   |   |   |   |   py.typed
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   +---functools
|   |       |   |   |   |   |   py.typed
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   __init__.pyi
|   |       |   |   |   |   |   
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   +---text
|   |       |   |   |   |   |   layouts.py
|   |       |   |   |   |   |   Lorem ipsum.txt
|   |       |   |   |   |   |   show-newlines.py
|   |       |   |   |   |   |   strip-prefix.py
|   |       |   |   |   |   |   to-dvorak.py
|   |       |   |   |   |   |   to-qwerty.py
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           layouts.cpython-312.pyc
|   |       |   |   |   |           show-newlines.cpython-312.pyc
|   |       |   |   |   |           strip-prefix.cpython-312.pyc
|   |       |   |   |   |           to-dvorak.cpython-312.pyc
|   |       |   |   |   |           to-qwerty.cpython-312.pyc
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   \---__pycache__
|   |       |   |   |           context.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---jaraco.collections-5.1.0.dist-info
|   |       |   |   |       INSTALLER
|   |       |   |   |       LICENSE
|   |       |   |   |       METADATA
|   |       |   |   |       RECORD
|   |       |   |   |       REQUESTED
|   |       |   |   |       top_level.txt
|   |       |   |   |       WHEEL
|   |       |   |   |       
|   |       |   |   +---jaraco.context-5.3.0.dist-info
|   |       |   |   |       INSTALLER
|   |       |   |   |       LICENSE
|   |       |   |   |       METADATA
|   |       |   |   |       RECORD
|   |       |   |   |       top_level.txt
|   |       |   |   |       WHEEL
|   |       |   |   |       
|   |       |   |   +---jaraco.functools-4.0.1.dist-info
|   |       |   |   |       INSTALLER
|   |       |   |   |       LICENSE
|   |       |   |   |       METADATA
|   |       |   |   |       RECORD
|   |       |   |   |       top_level.txt
|   |       |   |   |       WHEEL
|   |       |   |   |       
|   |       |   |   +---jaraco.text-3.12.1.dist-info
|   |       |   |   |       INSTALLER
|   |       |   |   |       LICENSE
|   |       |   |   |       METADATA
|   |       |   |   |       RECORD
|   |       |   |   |       REQUESTED
|   |       |   |   |       top_level.txt
|   |       |   |   |       WHEEL
|   |       |   |   |       
|   |       |   |   +---more_itertools
|   |       |   |   |   |   more.py
|   |       |   |   |   |   more.pyi
|   |       |   |   |   |   py.typed
|   |       |   |   |   |   recipes.py
|   |       |   |   |   |   recipes.pyi
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   __init__.pyi
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           more.cpython-312.pyc
|   |       |   |   |           recipes.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---more_itertools-10.3.0.dist-info
|   |       |   |   |       INSTALLER
|   |       |   |   |       LICENSE
|   |       |   |   |       METADATA
|   |       |   |   |       RECORD
|   |       |   |   |       REQUESTED
|   |       |   |   |       WHEEL
|   |       |   |   |       
|   |       |   |   +---packaging
|   |       |   |   |   |   markers.py
|   |       |   |   |   |   metadata.py
|   |       |   |   |   |   py.typed
|   |       |   |   |   |   requirements.py
|   |       |   |   |   |   specifiers.py
|   |       |   |   |   |   tags.py
|   |       |   |   |   |   utils.py
|   |       |   |   |   |   version.py
|   |       |   |   |   |   _elffile.py
|   |       |   |   |   |   _manylinux.py
|   |       |   |   |   |   _musllinux.py
|   |       |   |   |   |   _parser.py
|   |       |   |   |   |   _structures.py
|   |       |   |   |   |   _tokenizer.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   +---licenses
|   |       |   |   |   |   |   _spdx.py
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           _spdx.cpython-312.pyc
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   \---__pycache__
|   |       |   |   |           markers.cpython-312.pyc
|   |       |   |   |           metadata.cpython-312.pyc
|   |       |   |   |           requirements.cpython-312.pyc
|   |       |   |   |           specifiers.cpython-312.pyc
|   |       |   |   |           tags.cpython-312.pyc
|   |       |   |   |           utils.cpython-312.pyc
|   |       |   |   |           version.cpython-312.pyc
|   |       |   |   |           _elffile.cpython-312.pyc
|   |       |   |   |           _manylinux.cpython-312.pyc
|   |       |   |   |           _musllinux.cpython-312.pyc
|   |       |   |   |           _parser.cpython-312.pyc
|   |       |   |   |           _structures.cpython-312.pyc
|   |       |   |   |           _tokenizer.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---packaging-24.2.dist-info
|   |       |   |   |       INSTALLER
|   |       |   |   |       LICENSE
|   |       |   |   |       LICENSE.APACHE
|   |       |   |   |       LICENSE.BSD
|   |       |   |   |       METADATA
|   |       |   |   |       RECORD
|   |       |   |   |       REQUESTED
|   |       |   |   |       WHEEL
|   |       |   |   |       
|   |       |   |   +---platformdirs
|   |       |   |   |   |   android.py
|   |       |   |   |   |   api.py
|   |       |   |   |   |   macos.py
|   |       |   |   |   |   py.typed
|   |       |   |   |   |   unix.py
|   |       |   |   |   |   version.py
|   |       |   |   |   |   windows.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   __main__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           android.cpython-312.pyc
|   |       |   |   |           api.cpython-312.pyc
|   |       |   |   |           macos.cpython-312.pyc
|   |       |   |   |           unix.cpython-312.pyc
|   |       |   |   |           version.cpython-312.pyc
|   |       |   |   |           windows.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           __main__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---platformdirs-4.2.2.dist-info
|   |       |   |   |   |   INSTALLER
|   |       |   |   |   |   METADATA
|   |       |   |   |   |   RECORD
|   |       |   |   |   |   REQUESTED
|   |       |   |   |   |   WHEEL
|   |       |   |   |   |   
|   |       |   |   |   \---licenses
|   |       |   |   |           LICENSE
|   |       |   |   |           
|   |       |   |   +---tomli
|   |       |   |   |   |   py.typed
|   |       |   |   |   |   _parser.py
|   |       |   |   |   |   _re.py
|   |       |   |   |   |   _types.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           _parser.cpython-312.pyc
|   |       |   |   |           _re.cpython-312.pyc
|   |       |   |   |           _types.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---tomli-2.0.1.dist-info
|   |       |   |   |       INSTALLER
|   |       |   |   |       LICENSE
|   |       |   |   |       METADATA
|   |       |   |   |       RECORD
|   |       |   |   |       REQUESTED
|   |       |   |   |       WHEEL
|   |       |   |   |       
|   |       |   |   +---typeguard
|   |       |   |   |   |   py.typed
|   |       |   |   |   |   _checkers.py
|   |       |   |   |   |   _config.py
|   |       |   |   |   |   _decorators.py
|   |       |   |   |   |   _exceptions.py
|   |       |   |   |   |   _functions.py
|   |       |   |   |   |   _importhook.py
|   |       |   |   |   |   _memo.py
|   |       |   |   |   |   _pytest_plugin.py
|   |       |   |   |   |   _suppression.py
|   |       |   |   |   |   _transformer.py
|   |       |   |   |   |   _union_transformer.py
|   |       |   |   |   |   _utils.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           _checkers.cpython-312.pyc
|   |       |   |   |           _config.cpython-312.pyc
|   |       |   |   |           _decorators.cpython-312.pyc
|   |       |   |   |           _exceptions.cpython-312.pyc
|   |       |   |   |           _functions.cpython-312.pyc
|   |       |   |   |           _importhook.cpython-312.pyc
|   |       |   |   |           _memo.cpython-312.pyc
|   |       |   |   |           _pytest_plugin.cpython-312.pyc
|   |       |   |   |           _suppression.cpython-312.pyc
|   |       |   |   |           _transformer.cpython-312.pyc
|   |       |   |   |           _union_transformer.cpython-312.pyc
|   |       |   |   |           _utils.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---typeguard-4.3.0.dist-info
|   |       |   |   |       entry_points.txt
|   |       |   |   |       INSTALLER
|   |       |   |   |       LICENSE
|   |       |   |   |       METADATA
|   |       |   |   |       RECORD
|   |       |   |   |       top_level.txt
|   |       |   |   |       WHEEL
|   |       |   |   |       
|   |       |   |   +---typing_extensions-4.12.2.dist-info
|   |       |   |   |       INSTALLER
|   |       |   |   |       LICENSE
|   |       |   |   |       METADATA
|   |       |   |   |       RECORD
|   |       |   |   |       WHEEL
|   |       |   |   |       
|   |       |   |   +---wheel
|   |       |   |   |   |   bdist_wheel.py
|   |       |   |   |   |   macosx_libfile.py
|   |       |   |   |   |   metadata.py
|   |       |   |   |   |   util.py
|   |       |   |   |   |   wheelfile.py
|   |       |   |   |   |   _bdist_wheel.py
|   |       |   |   |   |   _setuptools_logging.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   __main__.py
|   |       |   |   |   |   
|   |       |   |   |   +---cli
|   |       |   |   |   |   |   convert.py
|   |       |   |   |   |   |   pack.py
|   |       |   |   |   |   |   tags.py
|   |       |   |   |   |   |   unpack.py
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           convert.cpython-312.pyc
|   |       |   |   |   |           pack.cpython-312.pyc
|   |       |   |   |   |           tags.cpython-312.pyc
|   |       |   |   |   |           unpack.cpython-312.pyc
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   +---vendored
|   |       |   |   |   |   |   vendor.txt
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   +---packaging
|   |       |   |   |   |   |   |   LICENSE
|   |       |   |   |   |   |   |   LICENSE.APACHE
|   |       |   |   |   |   |   |   LICENSE.BSD
|   |       |   |   |   |   |   |   markers.py
|   |       |   |   |   |   |   |   requirements.py
|   |       |   |   |   |   |   |   specifiers.py
|   |       |   |   |   |   |   |   tags.py
|   |       |   |   |   |   |   |   utils.py
|   |       |   |   |   |   |   |   version.py
|   |       |   |   |   |   |   |   _elffile.py
|   |       |   |   |   |   |   |   _manylinux.py
|   |       |   |   |   |   |   |   _musllinux.py
|   |       |   |   |   |   |   |   _parser.py
|   |       |   |   |   |   |   |   _structures.py
|   |       |   |   |   |   |   |   _tokenizer.py
|   |       |   |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   |   
|   |       |   |   |   |   |   \---__pycache__
|   |       |   |   |   |   |           markers.cpython-312.pyc
|   |       |   |   |   |   |           requirements.cpython-312.pyc
|   |       |   |   |   |   |           specifiers.cpython-312.pyc
|   |       |   |   |   |   |           tags.cpython-312.pyc
|   |       |   |   |   |   |           utils.cpython-312.pyc
|   |       |   |   |   |   |           version.cpython-312.pyc
|   |       |   |   |   |   |           _elffile.cpython-312.pyc
|   |       |   |   |   |   |           _manylinux.cpython-312.pyc
|   |       |   |   |   |   |           _musllinux.cpython-312.pyc
|   |       |   |   |   |   |           _parser.cpython-312.pyc
|   |       |   |   |   |   |           _structures.cpython-312.pyc
|   |       |   |   |   |   |           _tokenizer.cpython-312.pyc
|   |       |   |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |   |           
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   \---__pycache__
|   |       |   |   |           bdist_wheel.cpython-312.pyc
|   |       |   |   |           macosx_libfile.cpython-312.pyc
|   |       |   |   |           metadata.cpython-312.pyc
|   |       |   |   |           util.cpython-312.pyc
|   |       |   |   |           wheelfile.cpython-312.pyc
|   |       |   |   |           _bdist_wheel.cpython-312.pyc
|   |       |   |   |           _setuptools_logging.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           __main__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---wheel-0.45.1.dist-info
|   |       |   |   |       entry_points.txt
|   |       |   |   |       INSTALLER
|   |       |   |   |       LICENSE.txt
|   |       |   |   |       METADATA
|   |       |   |   |       RECORD
|   |       |   |   |       REQUESTED
|   |       |   |   |       WHEEL
|   |       |   |   |       
|   |       |   |   +---zipp
|   |       |   |   |   |   glob.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   +---compat
|   |       |   |   |   |   |   py310.py
|   |       |   |   |   |   |   __init__.py
|   |       |   |   |   |   |   
|   |       |   |   |   |   \---__pycache__
|   |       |   |   |   |           py310.cpython-312.pyc
|   |       |   |   |   |           __init__.cpython-312.pyc
|   |       |   |   |   |           
|   |       |   |   |   \---__pycache__
|   |       |   |   |           glob.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   +---zipp-3.19.2.dist-info
|   |       |   |   |       INSTALLER
|   |       |   |   |       LICENSE
|   |       |   |   |       METADATA
|   |       |   |   |       RECORD
|   |       |   |   |       REQUESTED
|   |       |   |   |       top_level.txt
|   |       |   |   |       WHEEL
|   |       |   |   |       
|   |       |   |   \---__pycache__
|   |       |   |           typing_extensions.cpython-312.pyc
|   |       |   |           
|   |       |   \---__pycache__
|   |       |           archive_util.cpython-312.pyc
|   |       |           build_meta.cpython-312.pyc
|   |       |           depends.cpython-312.pyc
|   |       |           discovery.cpython-312.pyc
|   |       |           dist.cpython-312.pyc
|   |       |           errors.cpython-312.pyc
|   |       |           extension.cpython-312.pyc
|   |       |           glob.cpython-312.pyc
|   |       |           installer.cpython-312.pyc
|   |       |           launch.cpython-312.pyc
|   |       |           logging.cpython-312.pyc
|   |       |           modified.cpython-312.pyc
|   |       |           monkey.cpython-312.pyc
|   |       |           msvc.cpython-312.pyc
|   |       |           namespaces.cpython-312.pyc
|   |       |           unicode_utils.cpython-312.pyc
|   |       |           version.cpython-312.pyc
|   |       |           warnings.cpython-312.pyc
|   |       |           wheel.cpython-312.pyc
|   |       |           windows_support.cpython-312.pyc
|   |       |           _core_metadata.cpython-312.pyc
|   |       |           _discovery.cpython-312.pyc
|   |       |           _entry_points.cpython-312.pyc
|   |       |           _imp.cpython-312.pyc
|   |       |           _importlib.cpython-312.pyc
|   |       |           _itertools.cpython-312.pyc
|   |       |           _normalization.cpython-312.pyc
|   |       |           _path.cpython-312.pyc
|   |       |           _reqs.cpython-312.pyc
|   |       |           _scripts.cpython-312.pyc
|   |       |           _shutil.cpython-312.pyc
|   |       |           _static.cpython-312.pyc
|   |       |           __init__.cpython-312.pyc
|   |       |           
|   |       +---setuptools-80.9.0.dist-info
|   |       |   |   entry_points.txt
|   |       |   |   INSTALLER
|   |       |   |   METADATA
|   |       |   |   RECORD
|   |       |   |   REQUESTED
|   |       |   |   top_level.txt
|   |       |   |   WHEEL
|   |       |   |   
|   |       |   \---licenses
|   |       |           LICENSE
|   |       |           
|   |       +---typing_extensions-4.15.0.dist-info
|   |       |   |   INSTALLER
|   |       |   |   METADATA
|   |       |   |   RECORD
|   |       |   |   WHEEL
|   |       |   |   
|   |       |   \---licenses
|   |       |           LICENSE
|   |       |           
|   |       +---typing_inspection
|   |       |   |   introspection.py
|   |       |   |   py.typed
|   |       |   |   typing_objects.py
|   |       |   |   typing_objects.pyi
|   |       |   |   __init__.py
|   |       |   |   
|   |       |   \---__pycache__
|   |       |           introspection.cpython-312.pyc
|   |       |           typing_objects.cpython-312.pyc
|   |       |           __init__.cpython-312.pyc
|   |       |           
|   |       +---typing_inspection-0.4.2.dist-info
|   |       |   |   INSTALLER
|   |       |   |   METADATA
|   |       |   |   RECORD
|   |       |   |   WHEEL
|   |       |   |   
|   |       |   \---licenses
|   |       |           LICENSE
|   |       |           
|   |       +---urllib3
|   |       |   |   connection.py
|   |       |   |   connectionpool.py
|   |       |   |   exceptions.py
|   |       |   |   fields.py
|   |       |   |   filepost.py
|   |       |   |   poolmanager.py
|   |       |   |   py.typed
|   |       |   |   response.py
|   |       |   |   _base_connection.py
|   |       |   |   _collections.py
|   |       |   |   _request_methods.py
|   |       |   |   _version.py
|   |       |   |   __init__.py
|   |       |   |   
|   |       |   +---contrib
|   |       |   |   |   pyopenssl.py
|   |       |   |   |   socks.py
|   |       |   |   |   __init__.py
|   |       |   |   |   
|   |       |   |   +---emscripten
|   |       |   |   |   |   connection.py
|   |       |   |   |   |   emscripten_fetch_worker.js
|   |       |   |   |   |   fetch.py
|   |       |   |   |   |   request.py
|   |       |   |   |   |   response.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           connection.cpython-312.pyc
|   |       |   |   |           fetch.cpython-312.pyc
|   |       |   |   |           request.cpython-312.pyc
|   |       |   |   |           response.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   \---__pycache__
|   |       |   |           pyopenssl.cpython-312.pyc
|   |       |   |           socks.cpython-312.pyc
|   |       |   |           __init__.cpython-312.pyc
|   |       |   |           
|   |       |   +---http2
|   |       |   |   |   connection.py
|   |       |   |   |   probe.py
|   |       |   |   |   __init__.py
|   |       |   |   |   
|   |       |   |   \---__pycache__
|   |       |   |           connection.cpython-312.pyc
|   |       |   |           probe.cpython-312.pyc
|   |       |   |           __init__.cpython-312.pyc
|   |       |   |           
|   |       |   +---util
|   |       |   |   |   connection.py
|   |       |   |   |   proxy.py
|   |       |   |   |   request.py
|   |       |   |   |   response.py
|   |       |   |   |   retry.py
|   |       |   |   |   ssltransport.py
|   |       |   |   |   ssl_.py
|   |       |   |   |   ssl_match_hostname.py
|   |       |   |   |   timeout.py
|   |       |   |   |   url.py
|   |       |   |   |   util.py
|   |       |   |   |   wait.py
|   |       |   |   |   __init__.py
|   |       |   |   |   
|   |       |   |   \---__pycache__
|   |       |   |           connection.cpython-312.pyc
|   |       |   |           proxy.cpython-312.pyc
|   |       |   |           request.cpython-312.pyc
|   |       |   |           response.cpython-312.pyc
|   |       |   |           retry.cpython-312.pyc
|   |       |   |           ssltransport.cpython-312.pyc
|   |       |   |           ssl_.cpython-312.pyc
|   |       |   |           ssl_match_hostname.cpython-312.pyc
|   |       |   |           timeout.cpython-312.pyc
|   |       |   |           url.cpython-312.pyc
|   |       |   |           util.cpython-312.pyc
|   |       |   |           wait.cpython-312.pyc
|   |       |   |           __init__.cpython-312.pyc
|   |       |   |           
|   |       |   \---__pycache__
|   |       |           connection.cpython-312.pyc
|   |       |           connectionpool.cpython-312.pyc
|   |       |           exceptions.cpython-312.pyc
|   |       |           fields.cpython-312.pyc
|   |       |           filepost.cpython-312.pyc
|   |       |           poolmanager.cpython-312.pyc
|   |       |           response.cpython-312.pyc
|   |       |           _base_connection.cpython-312.pyc
|   |       |           _collections.cpython-312.pyc
|   |       |           _request_methods.cpython-312.pyc
|   |       |           _version.cpython-312.pyc
|   |       |           __init__.cpython-312.pyc
|   |       |           
|   |       +---urllib3-2.5.0.dist-info
|   |       |   |   INSTALLER
|   |       |   |   METADATA
|   |       |   |   RECORD
|   |       |   |   WHEEL
|   |       |   |   
|   |       |   \---licenses
|   |       |           LICENSE.txt
|   |       |           
|   |       +---wheel
|   |       |   |   bdist_wheel.py
|   |       |   |   macosx_libfile.py
|   |       |   |   metadata.py
|   |       |   |   util.py
|   |       |   |   wheelfile.py
|   |       |   |   _bdist_wheel.py
|   |       |   |   _setuptools_logging.py
|   |       |   |   __init__.py
|   |       |   |   __main__.py
|   |       |   |   
|   |       |   +---cli
|   |       |   |   |   convert.py
|   |       |   |   |   pack.py
|   |       |   |   |   tags.py
|   |       |   |   |   unpack.py
|   |       |   |   |   __init__.py
|   |       |   |   |   
|   |       |   |   \---__pycache__
|   |       |   |           convert.cpython-312.pyc
|   |       |   |           pack.cpython-312.pyc
|   |       |   |           tags.cpython-312.pyc
|   |       |   |           unpack.cpython-312.pyc
|   |       |   |           __init__.cpython-312.pyc
|   |       |   |           
|   |       |   +---vendored
|   |       |   |   |   vendor.txt
|   |       |   |   |   __init__.py
|   |       |   |   |   
|   |       |   |   +---packaging
|   |       |   |   |   |   LICENSE
|   |       |   |   |   |   LICENSE.APACHE
|   |       |   |   |   |   LICENSE.BSD
|   |       |   |   |   |   markers.py
|   |       |   |   |   |   requirements.py
|   |       |   |   |   |   specifiers.py
|   |       |   |   |   |   tags.py
|   |       |   |   |   |   utils.py
|   |       |   |   |   |   version.py
|   |       |   |   |   |   _elffile.py
|   |       |   |   |   |   _manylinux.py
|   |       |   |   |   |   _musllinux.py
|   |       |   |   |   |   _parser.py
|   |       |   |   |   |   _structures.py
|   |       |   |   |   |   _tokenizer.py
|   |       |   |   |   |   __init__.py
|   |       |   |   |   |   
|   |       |   |   |   \---__pycache__
|   |       |   |   |           markers.cpython-312.pyc
|   |       |   |   |           requirements.cpython-312.pyc
|   |       |   |   |           specifiers.cpython-312.pyc
|   |       |   |   |           tags.cpython-312.pyc
|   |       |   |   |           utils.cpython-312.pyc
|   |       |   |   |           version.cpython-312.pyc
|   |       |   |   |           _elffile.cpython-312.pyc
|   |       |   |   |           _manylinux.cpython-312.pyc
|   |       |   |   |           _musllinux.cpython-312.pyc
|   |       |   |   |           _parser.cpython-312.pyc
|   |       |   |   |           _structures.cpython-312.pyc
|   |       |   |   |           _tokenizer.cpython-312.pyc
|   |       |   |   |           __init__.cpython-312.pyc
|   |       |   |   |           
|   |       |   |   \---__pycache__
|   |       |   |           __init__.cpython-312.pyc
|   |       |   |           
|   |       |   \---__pycache__
|   |       |           bdist_wheel.cpython-312.pyc
|   |       |           macosx_libfile.cpython-312.pyc
|   |       |           metadata.cpython-312.pyc
|   |       |           util.cpython-312.pyc
|   |       |           wheelfile.cpython-312.pyc
|   |       |           _bdist_wheel.cpython-312.pyc
|   |       |           _setuptools_logging.cpython-312.pyc
|   |       |           __init__.cpython-312.pyc
|   |       |           __main__.cpython-312.pyc
|   |       |           
|   |       +---wheel-0.45.1.dist-info
|   |       |       entry_points.txt
|   |       |       INSTALLER
|   |       |       LICENSE.txt
|   |       |       METADATA
|   |       |       RECORD
|   |       |       REQUESTED
|   |       |       WHEEL
|   |       |       
|   |       +---yaml
|   |       |   |   composer.py
|   |       |   |   constructor.py
|   |       |   |   cyaml.py
|   |       |   |   dumper.py
|   |       |   |   emitter.py
|   |       |   |   error.py
|   |       |   |   events.py
|   |       |   |   loader.py
|   |       |   |   nodes.py
|   |       |   |   parser.py
|   |       |   |   reader.py
|   |       |   |   representer.py
|   |       |   |   resolver.py
|   |       |   |   scanner.py
|   |       |   |   serializer.py
|   |       |   |   tokens.py
|   |       |   |   _yaml.cp312-win_amd64.pyd
|   |       |   |   __init__.py
|   |       |   |   
|   |       |   \---__pycache__
|   |       |           composer.cpython-312.pyc
|   |       |           constructor.cpython-312.pyc
|   |       |           cyaml.cpython-312.pyc
|   |       |           dumper.cpython-312.pyc
|   |       |           emitter.cpython-312.pyc
|   |       |           error.cpython-312.pyc
|   |       |           events.cpython-312.pyc
|   |       |           loader.cpython-312.pyc
|   |       |           nodes.cpython-312.pyc
|   |       |           parser.cpython-312.pyc
|   |       |           reader.cpython-312.pyc
|   |       |           representer.cpython-312.pyc
|   |       |           resolver.cpython-312.pyc
|   |       |           scanner.cpython-312.pyc
|   |       |           serializer.cpython-312.pyc
|   |       |           tokens.cpython-312.pyc
|   |       |           __init__.cpython-312.pyc
|   |       |           
|   |       +---_distutils_hack
|   |       |   |   override.py
|   |       |   |   __init__.py
|   |       |   |   
|   |       |   \---__pycache__
|   |       |           override.cpython-312.pyc
|   |       |           __init__.cpython-312.pyc
|   |       |           
|   |       +---_yaml
|   |       |   |   __init__.py
|   |       |   |   
|   |       |   \---__pycache__
|   |       |           __init__.cpython-312.pyc
|   |       |           
|   |       \---__pycache__
|   |               typing_extensions.cpython-312.pyc
|   |               
|   \---Scripts
|           activate
|           activate.bat
|           Activate.ps1
|           deactivate.bat
|           deep.exe
|           normalizer.exe
|           pip.exe
|           pip3.12.exe
|           pip3.exe
|           python.exe
|           pythonw.exe
|           wheel.exe
|           
+---01-bootstrap
|       adopt-devices.py
|       install-unifi-controller.sh
|       install-unifi.ps1
|       install-unifi.sh
|       vlan-stubs.json
|       
+---02-declarative-config
|       apply.py
|       config.gateway.json
|       policy-table.yaml
|       qos-smartqueue.yaml
|       vlans.yaml
|       
+---03-validation-ops
|       backup-cron.sh
|       check-critical-services.sh
|       phone-reg-test.py
|       validate-isolation.sh
|       
+---docs
|       adr-001-policy-over-fw.md
|       architecture-v5.mmd
|       dr-drill.md
|       guide.md
|       migration-runbook.md
|       troubleshooting.md
|       
+---rylan_ai_helpdesk
|   |   osticket-webhook.php
|   |   __init__.py
|   |   
|   +---triage_engine
|   |   |   main.py
|   |   |   __init__.py
|   |   |   
|   |   \---__pycache__
|   |           main.cpython-312.pyc
|   |           __init__.cpython-312.pyc
|   |           
|   \---__pycache__
|           __init__.cpython-312.pyc
|           
+---scripts
|       ignite.sh
|       tag-release.ps1
|       
+---shared
|   |   auth.py
|   |   inventory.yaml
|   |   unifi_client.py
|   |   
|   \---__pycache__
|           auth.cpython-312.pyc
|           unifi_client.cpython-312.pyc
|           
\---tests
    |   main.py
    |   test_bootstrap.py
    |   test_triage.py
    |   __init__.py
    |   
    \---__pycache__
            test_triage.cpython-312-pytest-7.4.4.pyc
            __init__.cpython-312.pyc
            


## File Count Summary
- Total Files: 57
- Python Files: 12
- YAML Files: 6
- Shell Scripts: 6
