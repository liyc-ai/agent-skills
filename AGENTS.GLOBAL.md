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

## 学术写作

- 写论文的目标是让读者看到 insight、让工作更容易被理解和接受，不是把每个短板都
  摊在正文最前面。
- 不要"自曝短处"：局限性和不确定性要写，但放在合适的位置（limitations、图注、
  supplementary），用中性、就事论事的语气，不要写成自我否定，也不要把 caveat
  当成段落的落脚点。
- 正文优先展示贡献、机制和可验证的结果；审稿人能从图里看到的误差条、个别任务的
  波动，不必在正文反复强调。
- 该有的关键限制不能藏，但也不主动把它变成叙事中心；先讲清楚做了什么、为什么
  有意思，再交代边界。
- 写可能负面的内容（limitations、小幅度提升、没赢的 task、不确定性）时，先判断
  这句话会不会招来审稿人追问；如果会，自己能不能用一两句话回答。一旦不好回答，
  就调整写法：换成更中性的表述，或移到图注、limitations、supplementary，不要
  放在正文最显眼的位置。不是隐瞒数据，而是不让正文主动制造自己回答不了的问题。
