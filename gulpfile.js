const autoprefixer = require('gulp-autoprefixer');
const CleanCSS = require('clean-css');
const gulp = require('gulp');
const sass = require('gulp-sass');
const rimraf = require('rimraf');
const sourcemaps = require('gulp-sourcemaps');

const stylesDestDirectory = 'static/dist/css';
const stylesSrcDirectory = 'themes/munsio/src/scss/**/*.scss';

gulp.task('watch', () => {
  gulp.watch(stylesSrcDirectory, ['styles']);
});

gulp.task('styles', ['clean:styles'], () =>
  gulp.src(stylesSrcDirectory)
    .pipe(sourcemaps.init())
      .pipe(sass().on('error', sass.logError))
      .pipe(autoprefixer())
    .pipe(sourcemaps.write({ sourceRoot: '/scss' }))
    .pipe(gulp.dest(stylesDestDirectory))
);


//gulp.task('minify:markup', () =>
//  gulp.src('public/**/*.html')
//    .pipe(htmlmin({ collapseWhitespace: true }))
//    .pipe(inline({
//      rootpath: 'public/',
//      handlers: (source, context, next) => {
//        if (source.type === 'css' && source.fileContent && !source.content) {
//          uncss(context.html, { htmlroot: 'public' }, (error, css) => {
//            if (error) throw error;
//            // eslint-disable-next-line no-param-reassign
//            source.content = '<style>${new CleanCSS({ level: 2 }).minify(css).styles}</style>';
//            next();
//          });
//        } else {
//          next();
//        }
//      },
//    }))
//    .pipe(gulp.dest('public'))
//);


gulp.task('clean:styles', () => rimraf.sync(stylesDestDirectory));

gulp.task('build', ['styles']);

gulp.task('default', ['watch']);