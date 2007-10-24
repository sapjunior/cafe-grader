#include <stdio.h>

int x[10000000];

int main() {
  int i,a,b;
  for(i=0;i<10000000;i++)
    x[i] = i;
  scanf("%d %d", &a, &b);
  printf("%d", a+b);
  return 0;
}
