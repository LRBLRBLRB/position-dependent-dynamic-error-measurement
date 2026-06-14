function create_dir_if_not_exist(path)
    % 检查路径是否为空
    if isempty(path)
        error('Path should not be empty. ');
    end

    % 检查路径是否已经存在
    if ~isfolder(path)
        % 创建目录
        mkdir(path);
        fprintf('Create the directory: %s\n', path);
    end

    % 检查路径中的每个父目录是否存在，并创建它们
    parentDir = fileparts(path);
    if ~isempty(parentDir) && ~isequal(parentDir, '.')
        create_dir_if_not_exist(parentDir);
    end
end
