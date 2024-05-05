set_param board.repoPaths $env(BOARD_REPO)
puts [get_board_parts -quiet -latest_file_version "*:${env(BOARD_NAME)}:*"]