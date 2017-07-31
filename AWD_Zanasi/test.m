x = 0:0.1:2*pi();
y = sin( x );
plot(x,y);
%print -dpng test.png;
saveas( gcf(), 'test.fig', 'fig' );
saveas( gcf(), 'test.png', 'png' );
exit()