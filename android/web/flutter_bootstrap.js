{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
  onEntrypointLoaded: async function(engineInitializer) {
    let appRunner = await engineInitializer.initializeEngine({
      canvasKitBaseUrl: "https://storage.flutter-io.cn/flutter_infra_release/canvaskit/",
    });
    await appRunner.runApp();
  }
});
