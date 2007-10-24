#include <malloc.h>
#include <stdio.h>

int main()
{
  int a, b, i;
  int *x = (int *)malloc(40000000);
  
  for(i=0;i<10000000;i++) {
    *x = i;
    x++;
  }
  
  scanf("%d %d", &a, &b);
  printf("%d\n", a+b);
  return 0;
}
