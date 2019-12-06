# LENA WAS standalone Buildpack
LENA WAS standalone Buildpack 은 cloud foundry 의 java buildpack 을 기반으로 만들어 졌습니다.
java buildpack 의 경우 tomcat 을 사용하도록 되어있으나, 해당 buildpack 에서는 LENA WAS 로 대체합니다.


## Usage
cf push 수행시 아래와 같이 본 빌드팩 의 github url 을 참조하도록 합니다.

```bash
$ cf push -b https://github.com/lenalaborg/lena-was-sa-buildpack.git
```

