function onThink(interval, lastExecution)
MENSAGEM = {
"Ours gms do not answer private message and does not ask for your account data.",
"Any suggestion, complaint or bug report can be made through our discord https://discord.gg/tCZMySup",
"Our ant-bot system with automatic detection works in two steps in login and scans",
"To make your donation just log solebra.online, Good Game.",
"To know which monsters are boosted, check our website.",
"our casino stay is at DP THAIS, have a good fun!!",
}
doBroadcastMessage(MENSAGEM[math.random(1,#MENSAGEM)],19)
return TRUE
end