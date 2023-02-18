---
layout: post
title: "FitnessAQ"
---

I made a chatbot as part of my assignment. You should be able to see something at the bottom right corner, you can click it to interact with it.
Once you're done please do click on [this](https://forms.gle/U3iQ1yhcm28JDVuN9) link to fill in the questionnaire.

<script>
  window.watsonAssistantChatOptions = {
    integrationID: "7123a7ec-cc73-44b8-ac61-3932d43d6268", // The ID of this integration.
    region: "jp-tok", // The region your integration is hosted in.
    serviceInstanceID: "a0b2e414-b3e8-4bd3-9927-52d5079a2467", // The ID of your service instance.
    onLoad: function(instance) { instance.render(); }
  };
  setTimeout(function(){
    const t=document.createElement('script');
    t.src="https://web-chat.global.assistant.watson.appdomain.cloud/versions/" + (window.watsonAssistantChatOptions.clientVersion || 'latest') + "/WatsonAssistantChatEntry.js";
    document.head.appendChild(t);
  });
</script>
