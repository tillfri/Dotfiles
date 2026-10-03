-- Orgmode: tasks, agenda and capture for work, thesis and personal life.
-- Files live in ~/org (inbox.org, work.org, thesis.org, personal.org).
--   <leader>oc  capture      <leader>oa  agenda      g?  help inside org buffers
return {
  'nvim-orgmode/orgmode',
  event = 'VeryLazy',
  ft = { 'org' },
  config = function()
    require('orgmode').setup {
      org_agenda_files = '~/org/**/*',
      org_default_notes_file = '~/org/inbox.org',
      org_todo_keywords = { 'TODO(t)', 'NEXT(n)', 'WAITING(w)', '|', 'DONE(d)', 'CANCELLED(c)' },
      org_log_done = 'time',
      org_deadline_warning_days = 7,
      org_hide_leading_stars = true,
      org_startup_folded = 'content',
      org_capture_templates = {
        t = { description = 'Inbox task', template = '* TODO %?\n  %U' },
        n = { description = 'Inbox note', template = '* %?\n  %U' },
        w = {
          description = 'Work task',
          template = '* TODO %?\n  %U',
          target = '~/org/work.org',
          headline = 'Tasks',
        },
        m = {
          description = 'Master thesis task',
          template = '* TODO %?\n  %U',
          target = '~/org/thesis.org',
          headline = 'Tasks',
        },
        p = {
          description = 'Personal task',
          template = '* TODO %?\n  %U',
          target = '~/org/personal.org',
          headline = 'Tasks',
        },
        d = {
          description = 'Task with deadline (inbox)',
          template = '* TODO %?\n  DEADLINE: %^t\n  %U',
        },
      },
    }
  end,
}
