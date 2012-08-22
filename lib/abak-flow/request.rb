# -*- encoding: utf-8 -*-
module Abak::Flow
  # @TODO Сделать класс, в котором собрать общие куски из задач

  program :name, 'Утилита для оформления pull request на github.com'
  program :version, Abak::Flow::VERSION
  program :description, 'Утилита, заточенная под git-flow но с использованием github.com'

  default_command :help
  command :publish do |c|
    c.syntax      = 'git request publish <Заголовок>'
    c.description = 'Оформить pull request из текущей ветки (feature -> develop, hotfix -> master)'

    # Опции нужны, если человек хочет запушить  `` ветку, с именем отличным от стандарта
    c.option '--head STRING', String, 'Имя ветки, которую нужно принять в качестве изменений'
    c.option '--base STRING', String, 'Имя ветки, в которую нужно принять изменения'

    c.action do |args, options|
      jira_browse_url = 'http://jira.dev.apress.ru/browse/'

      config = Abak::Flow::Config.current
      github_client = Abak::Flow::GithubClient.connect(config)
      pull_request = Abak::Flow::PullRequest.new(config, :head => options.head, :base => options.base)

      title = args.first.to_s.strip
      body = 'Я забыл какая это задача :('

      if pull_request.default_task =~ /^\w+\-\d{1,}$/
        title = pull_request.default_task if title.empty?
        body = jira_browse_url + pull_request.default_task
      end

      pull_request.title = title
      pull_request.body  = body

      exit unless pull_request.valid?

      # Запушим текущую ветку на origin
      say "=> Обновляю ветку #{pull_request.current_branch} на origin"
      Hub::Runner.execute('push', 'origin', pull_request.current_branch)

      # Запостим pull request на upstream
      say '=> Делаю pull request на upstream'
      begin
        result = github_client.create_pull_request(pull_request.from_repo, pull_request.base, pull_request.head, pull_request.title, pull_request.body)
        say color(result._links.html.href, :green).to_s
      rescue => e
        say color(e.message, :error).to_s
      end
    end
  end

  command :update do |c|
    c.syntax      = 'git request update'
    c.description = 'Обновить ветку на удаленном (origin) репозитории'

    c.option '--branch STRING', String, 'Имя ветки, которую нужно обновить'

    c.action do |args, options|
      HighLine.color_scheme = HighLine::SampleColorScheme.new

      repository     = Hub::Commands.send :local_repo
      current_branch = repository.current_branch.short_name

      # Проверим, что у нас настроен origin
      if repository.remote_by_name('origin').nil?
        say color('Необходимо настроить репозиторий origin (форк) для текущего пользователя', :error).to_s
        say color('=> git remote add origin https://Developer@github.com/abak-press/sample.git', :info).to_s
        exit
      end

      # Запушим текущую ветку на origin
      branch = options.branch || current_branch
      say "=> Обновляю ветку #{branch} на origin"
      Hub::Runner.execute('push', 'origin', branch)
    end
  end

  command :feature do |c|
    c.syntax      = 'git request feature <Название задачи>'
    c.description = 'Создать ветку для выполнения задачи. Лучше всего, если название задачи, будет ее номером из jira'

    c.action do |args, options|
      HighLine.color_scheme = HighLine::SampleColorScheme.new

      task = args.shift.to_s

      if task.empty?
        say color('Необходимо указать имя задачи, а лучше всего ее номер из jira', :error).to_s
        exit
      end

      unless task =~ /^\w+\-\d{1,}$/
        say '=> Вы приняли верное решение :)' && exit if agree("Лучше всего завести задачу с именем примерно такого формата PC-001, может попробуем заново? [y/n]:")
      end

      Hub::Runner.execute('flow', 'feature', 'start', task)
    end
  end

  command :hotfix do |c|
    c.syntax      = 'git request hotfix <Название задачи>'
    c.description = 'Создать ветку для выполнения bugfix задачи. Лучше всего, если название задачи, будет ее номером из jira'

    c.action do |args, options|
      HighLine.color_scheme = HighLine::SampleColorScheme.new

      task = args.shift.to_s

      if task.empty?
        say color('Необходимо указать имя задачи, а лучше всего ее номер из jira', :error).to_s
        exit
      end

      unless task =~ /^\w+\-\d{1,}$/
        say '=> Вы приняли верное решение :)' && exit if agree("Лучше всего завести задачу с именем примерно такого формата PC-001, может попробуем заново? [y/n]:")
      end

      Hub::Runner.execute('flow', 'hotfix', 'start', task)
    end
  end

  command :done do |c|
    c.syntax      = 'git request done'
    c.description = 'Завершить pull request. По умолчанию удаляются ветки как локальная (local), так и удаленная (origin)'

    c.option '--branch STRING', String, 'Имя ветки pull request которой нужно закрыть'
    c.option '--all', 'Удаляет ветку в локальном репозитории и в удалнном (local + origin) (по умолчанию)'
    c.option '--local', 'Удаляет ветку только в локальном репозитории (local)'
    c.option '--origin', 'Удаляет ветку в удаленном репозитории (origin)'

    c.action do |args, options|
      HighLine.color_scheme = HighLine::SampleColorScheme.new

      repository     = Hub::Commands.send :local_repo
      current_branch = repository.current_branch.short_name
      branch         = options.branch || current_branch

      type = :all
      if [options.local, options.origin].compact.count == 1
        type = options.local ? :local : :origin
      end

      if [:master, :develop].include? branch.to_sym
        say color('Извините, но нельзя удалить ветку develop или master', :error).to_s
        exit
      end

      warning = "Внимание! Alarm! Danger! Achtung\nЕсли вы удалите ветку на удаленном репозитории, а ваш pull request еще не приняли, вы рискуете потерять проделанную работу.\nВы уверены, что хотите продолжить?"
      if [:all, :origin].include?(type)
        say '=> Вы приняли верное решение :)' && exit unless agree("#{warning} [y/n]:")
      end

      # @TODO Проверку на наличие ветки на origin
      if [:all, :origin].include? type
        say "=> Удаляю ветку #{branch} на origin"
        Hub::Runner.execute('push', repository.main_project.remote.name, ':' + branch)
      end

      if [:all, :local].include? type
        remote_branch, task = current_branch.split('/').push(nil).map(&:to_s)

        say "=> Удаляю локальную ветку #{branch}"
        Hub::Runner.execute('checkout', 'develop')
        Hub::Runner.execute('branch', '-D', branch)
      end
    end
  end

  # TODO Отрефакторить эту какашку
  command :readycheck do |c|
    c.syntax      = 'git request readycheck'
    c.description = 'Проверить все ли настроено для работы с github и удаленным (origin) репозиторием'

    c.action do |args, options|
      HighLine.color_scheme = HighLine::SampleColorScheme.new
      repository     = Hub::Commands.send :local_repo
      current_branch = repository.current_branch.short_name

      api_user     = Hub::Commands.send(:git_reader).read_config('abak.apiuser').to_s
      api_token    = Hub::Commands.send(:git_reader).read_config('abak.apitoken').to_s
      config_proxy = Hub::Commands.send(:git_reader).read_config('abak.proxy')
      env_proxy    = ENV['http_proxy'] || ENV['HTTP_PROXY']

      errors = []

      # Проверим, что у нас настроен origin
      if repository.remote_by_name('origin').nil?
        errors << [
          'Необходимо настроить репозиторий origin (форк) для текущего пользователя',
          '=> git remote add origin https://Developer@github.com/abak-press/sample.git'
        ]
      end

      # Проверим, что у нас настроен upstream
      if repository.remote_by_name('upstream').nil?
        errors << [
          'Необходимо настроить репозиторий upstream (главный) для текущего пользователя',
          '=> git remote add upstream https://Developer@github.com/abak-press/sample.git'
        ]
      end

      # Проверим, что у нас указан апи юзер
      if api_user.empty?
        errors << [
          'Необходимо указать своего пользователя API github',
          '=> https://github.com/Strech/abak-flow/blob/master/README.md'
        ]
      end

      # Проверим, что у нас указан токен
      if api_token.empty?
        errors << [
          'Необходимо указать токен своего пользователя API github',
          '=> https://github.com/Strech/abak-flow/blob/master/README.md'
        ]
      end

      if config_proxy || env_proxy
        message = "== В качестве прокси будет установлено значение #{config_proxy || env_proxy} =="
        say color('=' * message.length, :info).to_s
        say color(message, :info).to_s
        say color('=' * message.length + "\n", :info).to_s
      end

      errors.each do |error|
        say "#{color(error.first, :error)}\n#{color(error.last, :info)}"
      end

      say color('Хм ... кажется у вас все готово к работе', :debug).to_s if errors.count.zero?
    end
  end
end