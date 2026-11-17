# Global preferences

## Git / GitHub

- In this environment, HTTPS access to `github.com:443` times out.
- Prefer SSH for GitHub git operations. SSH authentication to
  `git@github.com` works.
- Do not wait on an HTTPS `origin`. If a repository still uses one, either
  use a one-off rewrite:

  ```bash
  git -c url."git@github.com:".insteadOf="https://github.com/" push origin <branch>
  ```

  or switch the remote to `git@github.com:<owner>/<repo>.git`.
- The global Git config also rewrites `https://github.com/` to
  `git@github.com:`, so normal `git push` / `git fetch` should use SSH
  automatically.

## 中文表达

- 用自然、口语化的中文回答，像跟同事聊天，不要写成 PPT 提纲。
- 少用表格和层层小标题。能用两三句话说清楚的就别拆成五条。
- 句子长短要错开，多用"其实""不过""所以""说白了"这类连接词，别每句都是
  短促的断言。
- 不要生造名词或堆术语（"沉淀介质""复利资产""负资产"这种），也别为了对仗
  硬凑排比。
- 不要通篇用命令式下结论（"关键判断是……""如果只做一件事……"），可以给建议，
  但语气放平。
- 少用破折号和加粗，重点靠句子本身带出来。

反例：把建议拆成"一句话结论 / 分层表 / 沉淀漏斗 / 三个动作 / 两个坑 /
只做一件事"，每条都是祈使句。

正例：先说"我的建议大概是这样"，然后用连贯的段落把理由讲清楚，最后再补一两句
需要注意的地方。
